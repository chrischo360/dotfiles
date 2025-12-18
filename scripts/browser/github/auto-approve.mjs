#!/usr/bin/env node
import { setTimeout } from 'timers/promises';
import { launchBrowser, needsAuth } from '../lib/browser.mjs';
import { notify } from '../lib/notify.mjs';
import { buildPullsUrl, buildPrUrl } from '../lib/github.mjs';
import { loadConfig } from '../lib/config.mjs';

async function main() {
  const args = process.argv.slice(2);
  const repoArg = args[0];
  const headless = !args.includes('--no-headless');

  if (!repoArg) {
    console.error('Usage: auto-approve <REPO> [--mode <notify|auto>] [--no-headless] [--interval <ms>]');
    console.error('Example: auto-approve wayfair-shared/sf-ui-web --mode notify');
    process.exit(1);
  }

  const config = await loadConfig();
  const intervalIndex = args.indexOf('--interval');
  const pollInterval = intervalIndex !== -1
    ? parseInt(args[intervalIndex + 1], 10)
    : config.polling.builds;

  const modeIndex = args.indexOf('--mode');
  const mode = modeIndex !== -1 ? args[modeIndex + 1] : config.auto_approve.mode;

  if (mode !== 'notify' && mode !== 'auto') {
    console.error('❌ Invalid mode. Must be "notify" or "auto"');
    process.exit(1);
  }

  const [owner, repo] = repoArg.split('/');
  console.log(`🤖 Monitoring Dependabot PRs for ${owner}/${repo}`);
  console.log(`   Mode: ${mode}`);
  console.log(`   Polling every ${pollInterval / 1000}s\n`);

  const { browser, page } = await launchBrowser(headless);

  const processedPRs = new Set();

  try {
    while (true) {
      // Navigate to dependabot PRs
      const pullsUrl = `${buildPullsUrl(owner, repo)}?q=is:open+author:app/dependabot`;
      await page.goto(pullsUrl, { waitUntil: 'domcontentloaded', timeout: 60000 });

      if (await needsAuth(page)) {
        await notify('🔐 Auth Required', 'GitHub login needed');
        console.error('❌ Authentication required. Run: watch-pr-setup');
        process.exit(1);
      }

      // Find all open dependabot PRs
      const prElements = await page.locator('.js-issue-row').all();
      console.log(`🔍 Found ${prElements.length} open Dependabot PR(s) (${new Date().toLocaleTimeString()})`);

      for (const prElement of prElements) {
        const prLink = await prElement.locator('a.js-navigation-open').first();
        const href = await prLink.getAttribute('href');
        const prNumber = href?.split('/').pop();

        if (!prNumber || processedPRs.has(prNumber)) {
          continue;
        }

        const prUrl = buildPrUrl(owner, repo, prNumber);
        await page.goto(prUrl, { waitUntil: 'domcontentloaded' });

        // Check if all CI checks pass
        const mergeStatusSection = page.locator('.merge-status-list');
        const allChecks = await mergeStatusSection.locator('.merge-status-item').all();

        let allPassed = true;
        let hasPending = false;

        for (const check of allChecks) {
          const hasSuccess = await check.locator('.color-fg-success, .octicon-check').count() > 0;
          const hasFail = await check.locator('.color-fg-danger, .octicon-x').count() > 0;

          if (hasFail) {
            allPassed = false;
            break;
          }
          if (!hasSuccess) {
            hasPending = true;
          }
        }

        if (hasPending) {
          console.log(`  PR #${prNumber}: Checks still pending...`);
          continue;
        }

        if (allPassed && allChecks.length > 0) {
          if (mode === 'auto') {
            // Try to click approve button
            const approveButton = page.locator('button:has-text("Approve")').first();
            const canApprove = await approveButton.isVisible({ timeout: 1000 }).catch(() => false);

            if (canApprove) {
              await approveButton.click();
              await notify('✅ Auto-approved', `Dependabot PR #${prNumber}`, `${owner}/${repo}`);
              console.log(`✅ Auto-approved PR #${prNumber}`);
              processedPRs.add(prNumber);
            } else {
              console.log(`  PR #${prNumber}: Already approved or cannot approve`);
              processedPRs.add(prNumber);
            }
          } else {
            // Notify mode
            await notify('🤖 Dependabot Ready', `PR #${prNumber} ready for approval`, `${owner}/${repo}`);
            console.log(`📢 PR #${prNumber}: Ready for approval (all checks passed)`);
            processedPRs.add(prNumber);
          }
        } else if (!allPassed) {
          console.log(`  PR #${prNumber}: Some checks failed`);
        }
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
