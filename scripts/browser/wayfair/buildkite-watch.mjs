#!/usr/bin/env node
import { setTimeout } from 'timers/promises';
import { launchBrowser, needsAuth } from '../lib/browser.mjs';
import { notify } from '../lib/notify.mjs';
import { loadConfig } from '../lib/config.mjs';

async function main() {
  const args = process.argv.slice(2);
  const buildUrl = args[0];
  const headless = !args.includes('--no-headless');

  if (!buildUrl || !buildUrl.includes('buildkite.com')) {
    console.error('Usage: buildkite-watch <BUILD_URL> [--no-headless] [--interval <ms>]');
    console.error('Example: buildkite-watch https://buildkite.com/wayfair/sf-ui-web-dev/builds/12345');
    process.exit(1);
  }

  const config = await loadConfig();
  const intervalIndex = args.indexOf('--interval');
  const pollInterval = intervalIndex !== -1
    ? parseInt(args[intervalIndex + 1], 10)
    : config.polling.builds;

  // Extract build info from URL
  const urlMatch = buildUrl.match(/buildkite\.com\/([^\/]+)\/([^\/]+)\/builds\/(\d+)/);
  const [, org, pipeline, buildNumber] = urlMatch || [null, null, null, null];

  console.log(`🔍 Watching Buildkite build`);
  if (pipeline && buildNumber) {
    console.log(`   Pipeline: ${pipeline}`);
    console.log(`   Build: #${buildNumber}`);
  }
  console.log(`   Polling every ${pollInterval / 1000}s\n`);

  const { browser, page } = await launchBrowser(headless);

  try {
    await page.goto(buildUrl, { waitUntil: 'domcontentloaded', timeout: 60000 });

    if (await needsAuth(page)) {
      await notify('🔐 Auth Required', 'Buildkite login needed');
      console.error('❌ Authentication required. Please login manually.');
      process.exit(1);
    }

    while (true) {
      await page.reload({ waitUntil: 'domcontentloaded' });

      // Check build status using Buildkite's classes
      const isPassed = await page.locator('.build-state--passed, [data-state="passed"]').isVisible({ timeout: 1000 }).catch(() => false);
      const isFailed = await page.locator('.build-state--failed, [data-state="failed"]').isVisible({ timeout: 1000 }).catch(() => false);
      const isCanceled = await page.locator('.build-state--canceled, [data-state="canceled"]').isVisible({ timeout: 1000 }).catch(() => false);
      const isRunning = await page.locator('.build-state--running, [data-state="running"]').isVisible({ timeout: 1000 }).catch(() => false);

      if (isPassed) {
        await notify('✅ Build Passed', pipeline || 'Buildkite Build', `Build #${buildNumber || 'Unknown'}`);
        console.log('✅ Build passed!');
        break;
      } else if (isFailed) {
        await notify('❌ Build Failed', pipeline || 'Buildkite Build', `Build #${buildNumber || 'Unknown'}`);
        console.log('❌ Build failed.');

        // Try to get failing job info
        const failedJobs = await page.locator('[data-state="failed"] .job-name').allTextContents();
        if (failedJobs.length > 0) {
          console.log(`   Failed jobs: ${failedJobs.join(', ')}`);
        }
        break;
      } else if (isCanceled) {
        await notify('⚠️ Build Canceled', pipeline || 'Buildkite Build', `Build #${buildNumber || 'Unknown'}`);
        console.log('⚠️  Build was canceled.');
        break;
      } else if (isRunning) {
        // Try to get progress info
        const runningJobs = await page.locator('[data-state="running"] .job-name').allTextContents();
        console.log(`⏳ Running... (${new Date().toLocaleTimeString()})`);
        if (runningJobs.length > 0) {
          console.log(`   Active jobs: ${runningJobs.slice(0, 3).join(', ')}${runningJobs.length > 3 ? '...' : ''}`);
        }
      } else {
        console.log(`⏳ Waiting for build status... (${new Date().toLocaleTimeString()})`);
      }

      await setTimeout(pollInterval);
    }
  } finally {
    await browser.close();
  }
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
