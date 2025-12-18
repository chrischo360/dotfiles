#!/usr/bin/env node
import { checkGhAuth, getCurrentUser, discoverRepos, discoverPRs } from './lib/github-api.mjs';

async function test() {
  console.log('Testing GitHub API integration...\n');

  // Test 1: Check auth
  console.log('1. Checking gh CLI authentication...');
  const isAuthed = await checkGhAuth();
  console.log(`   ${isAuthed ? '✅' : '❌'} gh CLI authenticated: ${isAuthed}\n`);

  if (!isAuthed) {
    console.error('Please run: gh auth login');
    process.exit(1);
  }

  // Test 2: Get current user
  console.log('2. Fetching current user...');
  try {
    const user = await getCurrentUser();
    console.log(`   ✅ User: ${user.username} (${user.name})`);
    console.log(`      Email: ${user.email}\n`);
  } catch (err) {
    console.error(`   ❌ Error: ${err.message}\n`);
  }

  // Test 3: Discover repos
  console.log('3. Discovering your repos...');
  try {
    const repos = await discoverRepos();
    console.log(`   ✅ Found ${repos.length} repos:`);
    repos.slice(0, 5).forEach(repo => console.log(`      - ${repo}`));
    if (repos.length > 5) {
      console.log(`      ... and ${repos.length - 5} more`);
    }
    console.log();
  } catch (err) {
    console.error(`   ❌ Error: ${err.message}\n`);
  }

  // Test 4a: Discover open PRs
  console.log('4a. Discovering your open PRs...');
  try {
    const openPrs = await discoverPRs(false);
    console.log(`   ✅ Found ${openPrs.length} open PRs:`);
    openPrs.slice(0, 5).forEach(pr => {
      console.log(`      - #${pr.number}: ${pr.title} [${pr.state}]`);
      console.log(`        ${pr.url}`);
      console.log(`        Repo: ${pr.repo}`);
    });
    if (openPrs.length > 5) {
      console.log(`      ... and ${openPrs.length - 5} more`);
    }
    console.log();
  } catch (err) {
    console.error(`   ❌ Error: ${err.message}\n`);
  }

  // Test 4b: Discover all recent PRs
  console.log('4b. Discovering ALL your recent PRs (open, closed, merged)...');
  try {
    const allPrs = await discoverPRs(true);
    console.log(`   ✅ Found ${allPrs.length} total PRs:`);
    allPrs.slice(0, 5).forEach(pr => {
      console.log(`      - #${pr.number}: ${pr.title} [${pr.state}]`);
      console.log(`        ${pr.url}`);
      console.log(`        Repo: ${pr.repo}`);
    });
    if (allPrs.length > 5) {
      console.log(`      ... and ${allPrs.length - 5} more`);
    }
    console.log();
  } catch (err) {
    console.error(`   ❌ Error: ${err.message}\n`);
  }

  console.log('✅ All tests complete!');
}

test().catch(err => {
  console.error('Test failed:', err);
  process.exit(1);
});
