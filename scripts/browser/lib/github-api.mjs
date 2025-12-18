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
 * Check if user has commits in a repo
 */
async function hasCommits(repoFullName, username) {
  try {
    const commits = await ghApi(`/repos/${repoFullName}/commits?author=${username}&per_page=1`);
    return commits.length > 0;
  } catch {
    return false;
  }
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
 * Count user's PRs in a repo
 */
async function countRepoPRs(repoFullName) {
  try {
    const { stdout } = await execAsync(`gh search prs --repo=${repoFullName} --author=@me --limit 1 --json url`);
    const prs = JSON.parse(stdout);
    // gh search doesn't return total count easily, so we'll use a workaround
    // Get all PRs and count them (limit to 100 for performance)
    const { stdout: allPrs } = await execAsync(`gh search prs --repo=${repoFullName} --author=@me --limit 100 --json url`);
    return JSON.parse(allPrs).length;
  } catch {
    return 0;
  }
}

/**
 * Discover repos user contributes to
 * Filters repos where user has commits OR PRs, adds metadata
 */
export async function discoverRepos() {
  try {
    // Get current user first
    const user = await getCurrentUser();
    const username = user.username;

    // Get all repos owned/collaborated by user
    const ownedRepos = await ghApi('/user/repos?per_page=100&affiliation=owner,collaborator');

    const reposWithMetadata = [];

    // Filter repos and add metadata
    for (const repo of ownedRepos) {
      if (repo.archived || repo.fork) continue; // Skip archived and forked repos

      const repoName = repo.full_name;

      // Check if user has contributed (commits OR PRs)
      const [hasUserCommits, prCount] = await Promise.all([
        hasCommits(repoName, username),
        countRepoPRs(repoName),
      ]);

      // Skip repos with no contributions
      if (!hasUserCommits && prCount === 0) continue;

      // Get last commit metadata
      const lastCommit = await getLastCommit(repoName, username);

      reposWithMetadata.push({
        name: repoName,
        pr_count: prCount,
        last_commit: lastCommit,
      });
    }

    // Sort by most recent commit
    reposWithMetadata.sort((a, b) => {
      if (!a.last_commit) return 1;
      if (!b.last_commit) return -1;
      return new Date(b.last_commit.date) - new Date(a.last_commit.date);
    });

    return reposWithMetadata;
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
