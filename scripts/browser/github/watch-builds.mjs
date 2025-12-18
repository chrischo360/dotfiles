#!/usr/bin/env node
import { setTimeout } from 'timers/promises';
import { spawn } from 'child_process';
import { launchBrowser, needsAuth } from '../lib/browser.mjs';
import { notify } from '../lib/notify.mjs';
import { parsePrUrl } from '../lib/github.mjs';
import { loadConfig } from '../lib/config.mjs';

async function main() {
  const args = process.argv.slice(2);
  let prUrl = args[0];
  const headless = !args.includes('--no-headless');
  const onceMode = args.includes('--once');

  // If no URL provided, use fzf to select from cached PRs
  if (!prUrl || prUrl.startsWith('--')) {
    try {
      const { selectPR, checkFzf } = await import('../lib/interactive.mjs');

      if (!await checkFzf()) {
        console.error('❌ fzf is not installed. Install with: brew install fzf');
        console.error('Or provide a PR URL directly: scout watch-builds <PR_URL>');
        process.exit(1);
      }

      console.log('📋 Select a PR to watch:\n');
      prUrl = await selectPR();
      console.log(`Selected: ${prUrl}\n`);
    } catch (err) {
      console.error(`❌ ${err.message}`);
      console.error('\nUsage: watch-builds <PR_URL> [--once] [--no-headless] [--interval <ms>]');
      console.error('Example: watch-builds https://github.com/owner/repo/pull/123');
      process.exit(1);
    }
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
      const failedBuildkiteUrls = [];

      for (const check of allChecks) {
        const hasSuccess = await check.locator('.octicon-check').count() > 0;
        const hasFail = await check.locator('.octicon-x-circle-fill').count() > 0;
        const hasNeutral = await check.locator('.octicon-square-fill').count() > 0;

        if (hasSuccess) {
          passedCount++;
        } else if (hasFail) {
          failedCount++;

          // Extract URL from failed check
          const linkElement = await check.locator('a[href]').first();
          const href = await linkElement.getAttribute('href').catch(() => null);

          if (href && href.includes('buildkite.com')) {
            // Use direct buildkite URL
            const buildkiteUrl = href.startsWith('http') ? href : `https://buildkite.com${href}`;
            failedBuildkiteUrls.push(buildkiteUrl);
          }
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

          // Display Buildkite URLs in --once mode (but don't auto-launch)
          if (failedBuildkiteUrls.length > 0) {
            const uniqueUrls = [...new Set(failedBuildkiteUrls)];
            console.log(`\n🔗 Failed Buildkite build(s):`);
            for (const url of uniqueUrls) {
              console.log(`   ${url}`);
            }
          }
        } else if (currentState === 'pending') {
          console.log(`⏳ Checks still running: ${pendingCount} pending`);
        } else {
          console.log('⚠️  No checks found');
        }
        console.log(`\nSummary: ${passedCount} passed, ${failedCount} failed, ${neutralCount} neutral, ${pendingCount} pending`);
        break;
      }

      // Watch mode: handle state changes and initial state
      if (previousState === null) {
        // First check: if already failed, auto-launch buildkite-watch
        if (currentState === 'failed' && failedBuildkiteUrls.length > 0) {
          console.log(`❌ ${failedCount} check(s) already failed.`);

          const uniqueUrls = [...new Set(failedBuildkiteUrls)];
          console.log(`\n🔗 Found ${uniqueUrls.length} failed Buildkite build(s):`);

          for (const url of uniqueUrls) {
            console.log(`   ${url}`);
          }

          // Launch buildkite-watch for the first failed build
          const buildUrl = uniqueUrls[0];
          console.log(`\n🚀 Auto-launching buildkite-watch for: ${buildUrl}\n`);

          const scriptDir = new URL('../wayfair/', import.meta.url).pathname;
          const buildkiteScript = `${scriptDir}buildkite-watch.mjs`;

          spawn('node', [buildkiteScript, buildUrl], {
            detached: true,
            stdio: 'inherit'
          });

          break;
        } else if (currentState === 'passed') {
          console.log('✅ All checks already passed!');
          break;
        }

        // Set initial state and continue watching
        previousState = currentState;
      } else if (currentState !== previousState && currentState !== 'unknown') {
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

            // Auto-launch buildkite-watch for failed Buildkite checks
            if (failedBuildkiteUrls.length > 0) {
              const uniqueUrls = [...new Set(failedBuildkiteUrls)];
              console.log(`\n🔗 Found ${uniqueUrls.length} failed Buildkite build(s):`);

              for (const url of uniqueUrls) {
                console.log(`   ${url}`);
              }

              // Launch buildkite-watch for the first failed build
              const buildUrl = uniqueUrls[0];
              console.log(`\n🚀 Auto-launching buildkite-watch for: ${buildUrl}\n`);

              const scriptDir = new URL('../wayfair/', import.meta.url).pathname;
              const buildkiteScript = `${scriptDir}buildkite-watch.mjs`;

              spawn('node', [buildkiteScript, buildUrl], {
                detached: true,
                stdio: 'inherit'
              });
            }

            break;
          }
        }
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
