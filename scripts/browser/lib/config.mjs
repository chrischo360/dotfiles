import { readFile } from 'fs/promises';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';
import { existsSync } from 'fs';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const CONFIG_FILE = join(__dirname, '..', 'config.json');

export const DEFAULTS = {
  user: {
    github_username: null,
    watched_repos: [],
    recent_prs: [],
    last_updated: null,
  },
  polling: {
    builds: 30000,
    reviews: 60000,
    deploys: 60000,
    pr_dashboard: 300000,
  },
  notifications: {
    sound: 'default',
    enabled: true,
  },
  auto_approve: {
    mode: 'notify',
    allowed_bots: ['dependabot[bot]', 'renovate[bot]'],
    require_passing_checks: true,
  },
  deploy_tracker: {
    environments: ['staging', 'production'],
  },
  buildkite: {
    organization: 'wayfair',
  },
};

export async function loadConfig() {
  if (!existsSync(CONFIG_FILE)) {
    return DEFAULTS;
  }

  try {
    const userConfig = JSON.parse(await readFile(CONFIG_FILE, 'utf-8'));
    return mergeDeep(DEFAULTS, userConfig);
  } catch (err) {
    console.error('❌ Failed to load config.json:', err.message);
    console.warn('  Using default configuration');
    return DEFAULTS;
  }
}

function mergeDeep(target, source) {
  const result = { ...target };
  for (const key in source) {
    if (source[key] && typeof source[key] === 'object' && !Array.isArray(source[key])) {
      result[key] = mergeDeep(target[key] || {}, source[key]);
    } else {
      result[key] = source[key];
    }
  }
  return result;
}
