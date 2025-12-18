#!/usr/bin/env node
import { launchBrowser, needsAuth } from '../lib/browser.mjs';
import { notify } from '../lib/notify.mjs';
import { buildPullsUrl } from '../lib/github.mjs';

async function main() {
  const args = process.argv.slice(2);
  let repoArg = args[0];
  const headless = !args.includes('--no-headless');

  // If no repo provided, use fzf to select from cached repos
  if (!repoArg || repoArg.startsWith('--')) {
    try {
      const { selectRepo, checkFzf } = await import('../lib/interactive.mjs');

      if (!await checkFzf()) {
        console.error('❌ fzf is not installed. Install with: brew install fzf');
        console.error('Or provide a repo directly: scout review-queue <REPO>');
        process.exit(1);
      }

      console.log('📋 Select a repo:\n');
      repoArg = await selectRepo();
      console.log(`Selected: ${repoArg}\n`);
    } catch (err) {
      console.error(`❌ ${err.message}`);
      console.error('\nUsage: review-queue <REPO> [--user <username>] [--limit <n>] [--no-headless]');
      console.error('Example: review-queue wayfair-shared/sf-ui-web --limit 5');
      process.exit(1);
    }
  }

  const userIndex = args.indexOf('--user');
  const username = userIndex !== -1 ? args[userIndex + 1] : '@me';

  const limitIndex = args.indexOf('--limit');
  const limit = limitIndex !== -1 ? parseInt(args[limitIndex + 1], 10) : 10;

  const [owner, repo] = repoArg.split('/');
  const pullsUrl = `${buildPullsUrl(owner, repo)}?q=is:open+review-requested:${username}+sort:created-asc`;

  console.log(`🔍 Finding PRs needing review (${owner}/${repo})`);
  console.log(`   User: ${username}`);
  console.log(`   Limit: ${limit}\n`);

  const { browser, page } = await launchBrowser(headless);

  try {
    await page.goto(pullsUrl, { waitUntil: 'domcontentloaded', timeout: 60000 });

    if (await needsAuth(page)) {
      console.error('❌ Authentication required. Run: watch-pr-setup');
      process.exit(1);
    }

    // Extract PR information (sorted by oldest first from URL)
    const prElements = await page.locator('.js-issue-row').all();
    const displayCount = Math.min(limit, prElements.length);

    if (prElements.length === 0) {
      console.log('🎉 No PRs need your review!\n');
      await notify('🎉 Review Queue Empty', 'No pending reviews', `${owner}/${repo}`);
      await browser.close();
      return;
    }

    console.log(`📋 ${prElements.length} PR(s) need your review (showing oldest ${displayCount}):\n`);

    for (let i = 0; i < displayCount; i++) {
      const prElement = prElements[i];

      const titleElement = await prElement.locator('a.js-navigation-open').first();
      const title = await titleElement.textContent();
      const href = await titleElement.getAttribute('href');
      const prNumber = href?.split('/').pop();

      const authorElement = await prElement.locator('.opened-by a').first();
      const author = await authorElement.textContent();

      const relativeTimeElement = await prElement.locator('relative-time').first();
      const datetime = await relativeTimeElement.getAttribute('datetime');
      const age = datetime ? getRelativeTime(new Date(datetime)) : 'unknown';

      console.log(`${i + 1}. PR #${prNumber} (${age} old)`);
      console.log(`   ${title?.trim()}`);
      console.log(`   Author: ${author?.trim()}`);
      console.log(`   URL: https://github.com/${owner}/${repo}/pull/${prNumber}\n`);
    }

    if (prElements.length > limit) {
      console.log(`... and ${prElements.length - limit} more\n`);
    }

    await notify('📋 Review Queue', `${prElements.length} PR(s) need review`, `${owner}/${repo}`);
  } finally {
    await browser.close();
  }
}

function getRelativeTime(date) {
  const now = new Date();
  const diffMs = now - date;
  const diffDays = Math.floor(diffMs / (1000 * 60 * 60 * 24));
  const diffHours = Math.floor(diffMs / (1000 * 60 * 60));
  const diffMins = Math.floor(diffMs / (1000 * 60));

  if (diffDays > 0) {
    return `${diffDays} day${diffDays > 1 ? 's' : ''}`;
  } else if (diffHours > 0) {
    return `${diffHours} hour${diffHours > 1 ? 's' : ''}`;
  } else {
    return `${diffMins} minute${diffMins > 1 ? 's' : ''}`;
  }
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
