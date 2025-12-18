#!/usr/bin/env node
import { chromium } from 'playwright';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const authFile = join(__dirname, 'github-auth.json');

console.log('🔧 Opening Chromium for Wayfair Okta + GitHub Enterprise login...');
console.log('Auth file:', authFile);
console.log('\n📝 Steps:');
console.log('   1. Browser will open to Wayfair Okta');
console.log('   2. Sign in to Okta');
console.log('   3. Script will then navigate to GitHub');
console.log('   4. Wait until you see the GitHub repository page');
console.log('   5. Press Ctrl+C in this terminal when done\n');

let browser, context, page;
let isSaving = false;

// Handle Ctrl+C
process.on('SIGINT', async () => {
  if (isSaving) return; // Prevent double-save
  isSaving = true;

  console.log('\n💾 Saving authentication state...');

  try {
    const currentUrl = page.url();
    console.log(`Current URL: ${currentUrl}`);

    if (!currentUrl.includes('github.com')) {
      console.error('❌ Not on GitHub. Please navigate to GitHub after Okta login.');
      await browser.close();
      process.exit(1);
    }

    // Get cookies directly from context (most important for auth)
    console.log('Saving cookies and session data...');
    const cookies = await context.cookies();

    // Try to get localStorage, but don't fail if page is closed
    let localStorage = [];
    try {
      localStorage = await page.evaluate(() => {
        const items = [];
        for (let i = 0; i < window.localStorage.length; i++) {
          const key = window.localStorage.key(i);
          items.push({ name: key, value: window.localStorage.getItem(key) });
        }
        return items;
      });
    } catch (err) {
      console.log('Could not read localStorage (page closed), cookies should be sufficient');
    }

    const storageState = {
      cookies,
      origins: [{
        origin: 'https://github.com',
        localStorage
      }]
    };

    // Write to file
    const fs = await import('fs/promises');
    await fs.writeFile(authFile, JSON.stringify(storageState, null, 2));

    await browser.close();

    console.log('✅ Authentication saved (Okta + GitHub Enterprise)!');
    console.log(`Saved to: ${authFile}`);
    console.log('You can now run: watch-pr <PR_URL>');
    process.exit(0);
  } catch (err) {
    console.error('Error saving authentication:', err.message);
    console.error(err.stack);
    try {
      await browser.close();
    } catch (closeErr) {
      // Ignore close errors
    }
    process.exit(1);
  }
});

browser = await chromium.launch({
  headless: false,
});

context = await browser.newContext();
page = await context.newPage();

// Step 1: Go to Okta and wait for user to login
console.log('Opening Okta login page...');
await page.goto('https://wayfair.okta.com/');

console.log('Waiting 20 seconds for Okta login...\n');
await new Promise(resolve => setTimeout(resolve, 20000));

// Step 2: Navigate to GitHub Enterprise to complete Okta auth
console.log('Navigating to GitHub Enterprise (for Okta)...');
await page.goto('https://github.com/enterprises/wayfair-emu');

console.log('Waiting 20 seconds for Okta to complete...\n');
await new Promise(resolve => setTimeout(resolve, 20000));

// Step 3: Navigate to actual repo
console.log('Navigating to sf-ui-web repo...');
await page.goto('https://github.com/wayfair-shared/sf-ui-web');

console.log('Loaded GitHub repo. Press Ctrl+C when you see the repository page.\n');

// Wait indefinitely
await new Promise(() => {});
