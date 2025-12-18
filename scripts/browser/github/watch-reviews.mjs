#!/usr/bin/env node
import { setTimeout } from 'timers/promises';
import { launchBrowser, needsAuth } from '../lib/browser.mjs';
import { notify } from '../lib/notify.mjs';
import { buildPullsUrl } from '../lib/github.mjs';
import { loadConfig } from '../lib/config.mjs';

async function main() {
  const args = process.argv.slice(2);
  const repoArg = args[0];
  const headless = !args.includes('--no-headless');

  if (!repoArg) {
    console.error('Usage: watch-reviews <REPO> [--user <username>] [--no-headless] [--interval <ms>]');
    console.error('Example: watch-reviews wayfair-shared/sf-ui-web');
    process.exit(1);
  }

  const config = await loadConfig();
  const intervalIndex = args.indexOf('--interval');
  const pollInterval = intervalIndex !== -1
    ? parseInt(args[intervalIndex + 1], 10)
    : config.polling.reviews;

  const userIndex = args.indexOf('--user');
  const username = userIndex !== -1 ? args[userIndex + 1] : '@me';

  const [owner, repo] = repoArg.split('/');
  const pullsUrl = `${buildPullsUrl(owner, repo)}?q=is:open+review-requested:${username}`;

  console.log(`🔍 Watching review requests for ${owner}/${repo}`);
  console.log(`   User: ${username}`);
  console.log(`   Polling every ${pollInterval / 1000}s\n`);

  const { browser, page } = await launchBrowser(headless);

  try {
    await page.goto(pullsUrl, { waitUntil: 'domcontentloaded', timeout: 60000 });

    let previousCount = null;
    while (true) {
      await page.reload({ waitUntil: 'domcontentloaded' });

      if (await needsAuth(page)) {
        await notify('🔐 Auth Required', 'GitHub login needed');
        console.error('❌ Authentication required. Run: watch-pr-setup');
        process.exit(1);
      }

      // Count PRs requesting review
      const prElements = await page.locator('.js-issue-row').all();
      const currentCount = prElements.length;

      if (previousCount !== null && currentCount > previousCount) {
        const newRequests = currentCount - previousCount;
        await notify('📬 New Review Request', `${newRequests} new PR(s) need review`, `${owner}/${repo}`);
        console.log(`📬 ${newRequests} new review request(s)! Total: ${currentCount}`);
      } else if (previousCount !== null && currentCount < previousCount) {
        const completed = previousCount - currentCount;
        await notify('✅ Reviews Completed', `${completed} PR(s) reviewed`, `${owner}/${repo}`);
        console.log(`✅ ${completed} review(s) completed! Remaining: ${currentCount}`);
      }

      if (previousCount === null) {
        console.log(`📋 Currently ${currentCount} PR(s) awaiting your review`);
      } else {
        console.log(`⏳ Monitoring... ${currentCount} PR(s) (${new Date().toLocaleTimeString()})`);
      }

      previousCount = currentCount;
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
