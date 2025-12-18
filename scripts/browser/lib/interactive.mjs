import { spawn } from 'child_process';
import { loadConfig } from './config.mjs';

/**
 * Format date as relative time (e.g., "2 hours ago", "3 days ago")
 */
function formatRelativeTime(isoDate) {
  if (!isoDate) return 'never';

  const now = new Date();
  const date = new Date(isoDate);
  const diffMs = now - date;
  const diffSec = Math.floor(diffMs / 1000);
  const diffMin = Math.floor(diffSec / 60);
  const diffHour = Math.floor(diffMin / 60);
  const diffDay = Math.floor(diffHour / 24);
  const diffWeek = Math.floor(diffDay / 7);
  const diffMonth = Math.floor(diffDay / 30);

  if (diffSec < 60) return 'just now';
  if (diffMin < 60) return `${diffMin}m ago`;
  if (diffHour < 24) return `${diffHour}h ago`;
  if (diffDay < 7) return `${diffDay}d ago`;
  if (diffWeek < 4) return `${diffWeek}w ago`;
  if (diffMonth < 12) return `${diffMonth}mo ago`;
  return `${Math.floor(diffMonth / 12)}y ago`;
}

/**
 * Select a PR from cached PRs using fzf
 */
export async function selectPR() {
  const config = await loadConfig();
  const prs = config.user?.recent_prs || [];

  if (prs.length === 0) {
    throw new Error('No PRs found. Run: scout discover');
  }

  // Format PRs for fzf display with repo prefix and relative time
  const fzfInput = prs.map(pr => {
    const repoShort = pr.repo.split('/')[1]; // Get just the repo name without owner
    const timeAgo = formatRelativeTime(pr.updated_at);
    return `${pr.url}\t[${repoShort}] #${pr.number}: ${pr.title} (updated ${timeAgo})`;
  }).join('\n');

  return new Promise((resolve, reject) => {
    const fzf = spawn('fzf', ['--height', '40%', '--reverse', '--header', 'Select a PR:'], {
      stdio: ['pipe', 'pipe', 'inherit']
    });

    let output = '';

    fzf.stdout.on('data', (data) => {
      output += data.toString();
    });

    fzf.on('close', (code) => {
      if (code === 130) {
        reject(new Error('Selection cancelled'));
      } else if (code === 0) {
        // Extract URL from selected line (first column)
        const selectedUrl = output.trim().split('\t')[0];
        resolve(selectedUrl);
      } else {
        reject(new Error(`fzf exited with code ${code}`));
      }
    });

    fzf.on('error', (err) => {
      reject(new Error(`fzf error: ${err.message}`));
    });

    // Write input to fzf's stdin
    fzf.stdin.write(fzfInput);
    fzf.stdin.end();
  });
}

/**
 * Select a repo from cached repos using fzf
 */
export async function selectRepo() {
  const config = await loadConfig();
  const repos = config.user?.watched_repos || [];

  if (repos.length === 0) {
    throw new Error('No repos found. Run: scout discover');
  }

  return new Promise((resolve, reject) => {
    // Format repos with metadata for display
    const repoList = repos.map(repo => {
      // Handle both old format (string) and new format (object)
      if (typeof repo === 'string') {
        return repo;
      }

      const prInfo = repo.pr_count > 0 ? `${repo.pr_count} PRs` : 'no PRs';
      const commitInfo = repo.last_commit
        ? `last commit ${formatRelativeTime(repo.last_commit.date)}`
        : 'no commits';

      return `${repo.name}\t(${prInfo}, ${commitInfo})`;
    }).join('\n');

    const fzf = spawn('fzf', ['--height', '40%', '--reverse', '--header', 'Select a repo:'], {
      stdio: ['pipe', 'pipe', 'inherit']
    });

    let output = '';

    fzf.stdout.on('data', (data) => {
      output += data.toString();
    });

    fzf.on('close', (code) => {
      if (code === 130) {
        reject(new Error('Selection cancelled'));
      } else if (code === 0) {
        // Extract repo name (before tab character)
        const selected = output.trim().split('\t')[0];
        resolve(selected);
      } else {
        reject(new Error(`fzf exited with code ${code}`));
      }
    });

    fzf.on('error', (err) => {
      reject(new Error(`fzf error: ${err.message}`));
    });

    // Write input to fzf's stdin
    fzf.stdin.write(repoList);
    fzf.stdin.end();
  });
}

/**
 * Check if fzf is available
 */
export async function checkFzf() {
  return new Promise((resolve) => {
    const which = spawn('which', ['fzf']);
    which.on('close', (code) => {
      resolve(code === 0);
    });
  });
}
