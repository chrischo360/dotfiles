#!/usr/bin/env node
import { checkGhAuth, getCurrentUser, discoverRepos, discoverPRs, cacheUserData } from '../lib/github-api.mjs';

async function main() {
  console.log('🔍 Discovering your GitHub repos and PRs...\n');

  // Check gh auth
  const isAuthed = await checkGhAuth();
  if (!isAuthed) {
    console.error('❌ gh CLI is not authenticated');
    console.error('   Run: gh auth login');
    process.exit(1);
  }

  try {
    // Get user info
    console.log('1. Fetching user info...');
    const user = await getCurrentUser();
    console.log(`   ✅ User: ${user.username} (${user.name})`);

    // Discover repos (derived from PRs - much faster!)
    console.log('\n2. Discovering your repos...');
    const repos = await discoverRepos();
    console.log(`   ✅ Found ${repos.length} repos with contributions`);
    if (repos.length > 0) {
      console.log(`\n   Top 5 by recent activity:`);
      repos.slice(0, 5).forEach(repo => {
        const commitInfo = repo.last_commit
          ? `commit: ${repo.last_commit.date.split('T')[0]}`
          : 'commit: fetching...';
        console.log(`      - ${repo.name} (${repo.pr_count} PRs, ${commitInfo})`);
      });
      if (repos.length > 5) {
        console.log(`      ... and ${repos.length - 5} more`);
      }
    }

    // Discover PRs
    console.log('\n3. Discovering your open PRs...');
    const prs = await discoverPRs();
    console.log(`   ✅ Found ${prs.length} open PRs`);
    if (prs.length > 0) {
      console.log(`   Recent PRs:`);
      prs.slice(0, 5).forEach(pr => {
        console.log(`      - #${pr.number}: ${pr.title}`);
        console.log(`        ${pr.repo}`);
      });
      if (prs.length > 5) {
        console.log(`      ... and ${prs.length - 5} more`);
      }
    }

    // Cache to config
    console.log('\n4. Caching to config.json...');
    await cacheUserData({
      github_username: user.username,
      watched_repos: repos,
      recent_prs: prs,
    });
    console.log('   ✅ Cached successfully');

    console.log('\n✅ Discovery complete!');
    console.log(`\nYou can now use:`);
    console.log(`  scout watch-builds    # Interactive menu of your PRs`);
    console.log(`  scout pr-dashboard    # Dashboard for your repos`);
  } catch (err) {
    console.error(`\n❌ Discovery failed: ${err.message}`);
    process.exit(1);
  }
}

main().catch(err => {
  console.error(err);
  process.exit(1);
});
