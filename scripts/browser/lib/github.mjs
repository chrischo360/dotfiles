export function parsePrUrl(url) {
  const prMatch = url.match(/github\.com\/([^\/]+)\/([^\/]+)\/pull\/(\d+)/);
  if (!prMatch) {
    throw new Error('Invalid GitHub PR URL format');
  }
  const [, owner, repo, prNumber] = prMatch;
  return { owner, repo, prNumber };
}

export function parseRepoUrl(url) {
  const repoMatch = url.match(/github\.com\/([^\/]+)\/([^\/]+)/);
  if (!repoMatch) {
    throw new Error('Invalid GitHub repo URL format');
  }
  const [, owner, repo] = repoMatch;
  return { owner, repo: repo.replace(/\.git$/, '') };
}

export function buildPrUrl(owner, repo, prNumber) {
  return `https://github.com/${owner}/${repo}/pull/${prNumber}`;
}

export function buildRepoUrl(owner, repo) {
  return `https://github.com/${owner}/${repo}`;
}

export function buildPullsUrl(owner, repo) {
  return `https://github.com/${owner}/${repo}/pulls`;
}
