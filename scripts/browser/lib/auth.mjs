import { fileURLToPath } from 'url';
import { dirname, join } from 'path';
import { existsSync } from 'fs';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

export const AUTH_FILE = join(__dirname, '..', 'github-auth.json');

export function hasAuth() {
  return existsSync(AUTH_FILE);
}

export function requireAuth() {
  if (!hasAuth()) {
    console.error('❌ GitHub authentication not found.');
    console.error('Run: watch-pr-setup');
    process.exit(1);
  }
}
