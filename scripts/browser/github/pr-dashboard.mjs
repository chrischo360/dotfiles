#!/usr/bin/env node
import { launchBrowser, needsAuth } from '../lib/browser.mjs';
import { notify } from '../lib/notify.mjs';
import { buildPullsUrl } from '../lib/github.mjs';

async function main() {
  const args = process.argv.slice(2);
  const repoArg = args[0];
  const headless = !args.includes('--no-headless');
  const format = args.includes('--format') ? args[args.indexOf('--format') + 1] : 'console';

  if (!repoArg) {
    console.error('Usage: pr-dashboard <REPO> [--format <console|json>] [--no-headless]');
    console.error('Example: pr-dashboard wayfair-shared/sf-ui-web');
    process.exit(1);
  }

  const [owner, repo] = repoArg.split('/');
  const pullsUrl = `${buildPullsUrl(owner, repo)}?q=is:open+author:@me`;

  const { browser, page } = await launchBrowser(headless);

  try {
    await page.goto(pullsUrl, { waitUntil: 'domcontentloaded', timeout: 60000 });

    if (await needsAuth(page)) {
      console.error('❌ Authentication required. Run: watch-pr-setup');
      process.exit(1);
    }

    // Extract PR information
    const prElements = await page.locator('.js-issue-row').all();
    const prs = [];

    for (const prElement of prElements) {
      const titleElement = await prElement.locator('a.js-navigation-open').first();
      const title = await titleElement.textContent();
      const href = await titleElement.getAttribute('href');
      const prNumber = href?.split('/').pop();

      const authorElement = await prElement.locator('.opened-by a').first();
      const author = await authorElement.textContent();

      // Check for labels indicating status
      const labels = await prElement.locator('.IssueLabel').allTextContents();

      // Determine review status (this is approximate, full status requires visiting each PR)
      let status = 'pending';
      if (labels.some(l => l.includes('approved'))) {
        status = 'approved';
      } else if (labels.some(l => l.includes('changes requested'))) {
        status = 'changes-requested';
      }

      prs.push({
        number: prNumber,
        title: title?.trim(),
        author: author?.trim(),
        status,
        labels: labels.filter(l => l.trim()),
      });
    }

    if (format === 'json') {
      console.log(JSON.stringify({ owner, repo, total: prs.length, prs }, null, 2));
    } else {
      // Console format
      console.log(`\n📊 PR Dashboard for ${owner}/${repo}\n`);
      console.log(`Total Open PRs: ${prs.length}\n`);

      const approved = prs.filter(pr => pr.status === 'approved').length;
      const changesRequested = prs.filter(pr => pr.status === 'changes-requested').length;
      const pending = prs.filter(pr => pr.status === 'pending').length;

      console.log(`Status Summary:`);
      console.log(`  ✅ Approved: ${approved}`);
      console.log(`  ⚠️  Changes Requested: ${changesRequested}`);
      console.log(`  ⏳ Pending: ${pending}\n`);

      if (prs.length > 0) {
        console.log(`Recent PRs:\n`);
        prs.slice(0, 10).forEach(pr => {
          const statusIcon = pr.status === 'approved' ? '✅' : pr.status === 'changes-requested' ? '⚠️' : '⏳';
          console.log(`  ${statusIcon} #${pr.number}: ${pr.title}`);
          console.log(`     Author: ${pr.author}\n`);
        });

        if (prs.length > 10) {
          console.log(`  ... and ${prs.length - 10} more\n`);
        }
      }
    }

    await notify('📊 Dashboard Generated', `${prs.length} open PRs`, `${owner}/${repo}`);
  } finally {
    await browser.close();
  }
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
