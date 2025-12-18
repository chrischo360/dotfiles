#!/usr/bin/env node
import { setTimeout } from 'timers/promises';
import { launchBrowser, needsAuth } from '../lib/browser.mjs';
import { notify } from '../lib/notify.mjs';
import { parsePrUrl } from '../lib/github.mjs';
import { loadConfig } from '../lib/config.mjs';

async function main() {
  const args = process.argv.slice(2);
  const prUrl = args[0];
  const headless = !args.includes('--no-headless');
  const onceMode = args.includes('--once');

  if (!prUrl) {
    console.error('Usage: watch-builds <PR_URL> [--once] [--no-headless] [--interval <ms>]');
    console.error('Example: watch-builds https://github.com/owner/repo/pull/123');
    console.error('');
    console.error('Flags:');
    console.error('  --once        Report current state and exit (no watching)');
    console.error('  --no-headless Run browser in visible mode');
    console.error('  --interval    Custom polling interval in ms (default: 30000)');
    process.exit(1);
  }

  const config = await loadConfig();
  const intervalIndex = args.indexOf('--interval');
  const pollInterval = intervalIndex !== -1
    ? parseInt(args[intervalIndex + 1], 10)
    : config.polling.builds;

  const { owner, repo, prNumber } = parsePrUrl(prUrl);
  if (onceMode) {
    console.log(`🔍 Checking CI status for PR #${prNumber} (${owner}/${repo})\n`);
  } else {
    console.log(`🔍 Watching CI checks for PR #${prNumber} (${owner}/${repo})`);
    console.log(`   Polling every ${pollInterval / 1000}s\n`);
  }

  const { browser, page } = await launchBrowser(headless);

  try {
    await page.goto(prUrl, { waitUntil: 'domcontentloaded', timeout: 60000 });

    let previousState = null;
    while (true) {
      await page.reload({ waitUntil: 'domcontentloaded' });

      if (await needsAuth(page)) {
        await notify('🔐 Auth Required', `PR #${prNumber}`, 'GitHub login needed');
        console.error('❌ Authentication required. Run: watch-pr-setup');
        process.exit(1);
      }

      // Wait for checks section to load
      try {
        await page.locator('section[aria-label="Checks"]').waitFor({ state: 'visible', timeout: 10000 });
      } catch (err) {
        console.log('⏳ Checks section not yet visible, waiting...');
        await setTimeout(pollInterval);
        continue;
      }

      // Expand collapsed check groups if needed
      const collapsedButtons = await page.locator('button[aria-label*="Collapse"][aria-expanded="false"]').all();
      for (const button of collapsedButtons) {
        await button.click();
      }

      // Check CI status - look for checks section
      const checksSection = page.locator('section[aria-label="Checks"]');
      const allChecks = await checksSection.locator('li[id*="list-view-node"]').all();

      if (allChecks.length === 0) {
        console.log('⚠️  No checks found - GitHub UI may have changed');
      }

      let passedCount = 0;
      let failedCount = 0;
      let pendingCount = 0;
      let neutralCount = 0;

      for (const check of allChecks) {
        const hasSuccess = await check.locator('.octicon-check').count() > 0;
        const hasFail = await check.locator('.octicon-x-circle-fill').count() > 0;
        const hasNeutral = await check.locator('.octicon-square-fill').count() > 0;

        if (hasSuccess) {
          passedCount++;
        } else if (hasFail) {
          failedCount++;
        } else if (hasNeutral) {
          neutralCount++;
        } else {
          pendingCount++;
        }
      }

      let currentState = 'unknown';
      if (allChecks.length > 0) {
        if (failedCount > 0) {
          currentState = 'failed';
        } else if (pendingCount > 0) {
          currentState = 'pending';
        } else if (passedCount > 0) {
          currentState = 'passed';
        }
      }

      // --once mode: report current state and exit
      if (onceMode) {
        if (currentState === 'passed') {
          console.log('✅ All checks passed!');
        } else if (currentState === 'failed') {
          console.log(`❌ ${failedCount} check(s) failed.`);
        } else if (currentState === 'pending') {
          console.log(`⏳ Checks still running: ${pendingCount} pending`);
        } else {
          console.log('⚠️  No checks found');
        }
        console.log(`\nSummary: ${passedCount} passed, ${failedCount} failed, ${neutralCount} neutral, ${pendingCount} pending`);
        break;
      }

      // Watch mode: only notify on transition from pending to complete
      if (currentState !== previousState && currentState !== 'unknown') {
        // Only exit if transitioning FROM pending or if we've seen pending before
        const shouldNotify = previousState === 'pending' ||
                            (previousState !== null && currentState !== 'pending');

        if (shouldNotify) {
          if (currentState === 'passed') {
            await notify('✅ CI Passed', `PR #${prNumber}`, `${owner}/${repo} - All checks passed`);
            console.log('✅ All checks passed!');
            break;
          } else if (currentState === 'failed') {
            await notify('❌ CI Failed', `PR #${prNumber}`, `${owner}/${repo} - Some checks failed`);
            console.log(`❌ ${failedCount} check(s) failed.`);
            break;
          }
        }
        previousState = currentState;
      } else if (previousState === null) {
        // First check: set initial state
        previousState = currentState;
      }

      console.log(`⏳ Checks: ${passedCount} passed, ${failedCount} failed, ${neutralCount} neutral, ${pendingCount} pending (${new Date().toLocaleTimeString()})`);
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
