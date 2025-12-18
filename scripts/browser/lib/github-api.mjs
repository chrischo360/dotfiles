import { exec } from 'child_process';
import { promisify } from 'util';
import { writeFile } from 'fs/promises';
import { loadConfig } from './config.mjs';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';

const execAsync = promisify(exec);
const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const CONFIG_FILE = join(__dirname, '..', 'config.json');

/**
 * Check if gh CLI is authenticated
 */
export async function checkGhAuth() {
  try {
    await execAsync('gh auth status');
    return true;
  } catch (err) {
    return false;
  }
}

/**
 * Execute gh api command and parse JSON response
 */
export async function ghApi(endpoint) {
  try {
    const { stdout } = await execAsync(`gh api ${endpoint}`);
    return JSON.parse(stdout);
  } catch (err) {
    throw new Error(`GitHub API request failed: ${err.message}`);
  }
}

/**
 * Get current authenticated user info
 */
export async function getCurrentUser() {
  try {
    const user = await ghApi('/user');
    return {
      username: user.login,
      name: user.name,
      email: user.email,
    };
  } catch (err) {
    throw new Error(`Failed to get current user: ${err.message}`);
  }
}

/**
 * Sleep helper for rate limiting
 */
async function sleep(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

/**
 * Get user's last commit in a repo
 */
async function getLastCommit(repoFullName, username) {
  try {
    const commits = await ghApi(`/repos/${repoFullName}/commits?author=${username}&per_page=1`);
    if (commits.length === 0) return null;

    const commit = commits[0];
    return {
      date: commit.commit.author.date,
      message: commit.commit.message.split('\n')[0], // First line only
      sha: commit.sha.substring(0, 7), // Short SHA
    };
  } catch {
    return null;
  }
}

/**
 * Discover repos user contributes to
 * Derives repos from PRs (much faster than checking each repo)
 */
export async function discoverRepos() {
  try {
    console.log('   Fetching all your PRs...');
    // Get ALL user's PRs (both open and closed)
    const allPrs = await discoverPRs(true); // includeAll=true

    // Group PRs by repo
    const repoMap = new Map();
    for (const pr of allPrs) {
      if (!repoMap.has(pr.repo)) {
        repoMap.set(pr.repo, { name: pr.repo, prs: [] });
      }
      repoMap.get(pr.repo).prs.push(pr);
    }

    console.log(`   Found ${repoMap.size} repos with PRs`);

    // Convert to array with metadata
    const repos = Array.from(repoMap.values()).map(repo => ({
      name: repo.name,
      pr_count: repo.prs.length,
      last_pr_update: repo.prs[0].updated_at, // Most recent PR
      last_commit: null, // Will be filled for top repos
    }));

    // Sort by most recent PR activity
    repos.sort((a, b) => {
      return new Date(b.last_pr_update) - new Date(a.last_pr_update);
    });

    // Get commit metadata for top 20 most active repos (to avoid rate limits)
    console.log('   Fetching commit metadata for top 20 repos...');
    const user = await getCurrentUser();
    const username = user.username;

    const topRepos = repos.slice(0, 20);
    for (let i = 0; i < topRepos.length; i++) {
      const repo = topRepos[i];
      console.log(`   [${i + 1}/20] ${repo.name}`);
      repo.last_commit = await getLastCommit(repo.name, username);
      await sleep(100); // 100ms delay to avoid rate limits
    }

    return repos;
  } catch (err) {
    throw new Error(`Failed to discover repos: ${err.message}`);
  }
}

/**
 * Discover PRs authored by user
 * Returns recent PRs (open, closed, or merged)
 */
export async function discoverPRs(includeAll = false) {
  try {
    // Use gh search prs command instead of gh api
    const stateFlag = includeAll ? '' : '--state=open';
    const cmd = `gh search prs --author=@me ${stateFlag} --limit 50 --json number,title,url,repository,state,updatedAt`;

    const { stdout } = await execAsync(cmd);
    const prs = JSON.parse(stdout);

    // Format the response to match our expected structure
    return prs.map(pr => ({
      number: pr.number,
      title: pr.title,
      url: pr.url,
      repo: pr.repository.nameWithOwner,
      state: pr.state,
      updated_at: pr.updatedAt,
    }));
  } catch (err) {
    throw new Error(`Failed to discover PRs: ${err.message}`);
  }
}

/**
 * Cache user data to config.json
 */
export async function cacheUserData(userData) {
  try {
    const config = await loadConfig();

    const updatedConfig = {
      ...config,
      user: {
        ...config.user,
        ...userData,
        last_updated: new Date().toISOString(),
      },
    };

    await writeFile(CONFIG_FILE, JSON.stringify(updatedConfig, null, 2), 'utf-8');
    return updatedConfig;
  } catch (err) {
    throw new Error(`Failed to cache user data: ${err.message}`);
  }
}
