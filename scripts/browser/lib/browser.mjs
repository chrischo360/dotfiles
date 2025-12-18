import { chromium } from 'playwright';
import { AUTH_FILE, requireAuth } from './auth.mjs';

export async function launchBrowser(headless = true) {
  requireAuth();

  let browser, context, page;
  try {
    browser = await chromium.launch({ headless });
    context = await browser.newContext({
      storageState: AUTH_FILE,
    });
    page = await context.newPage();
    return { browser, context, page };
  } catch (err) {
    console.error('❌ Failed to launch browser.');
    console.error('Run: cd ~/dotfiles/scripts/browser && npx playwright install chromium');
    console.error(err.message);
    process.exit(1);
  }
}

export async function needsAuth(page) {
  return await page.locator('input[name="login"]').isVisible({ timeout: 1000 }).catch(() => false);
}
