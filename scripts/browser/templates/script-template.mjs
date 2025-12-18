#!/usr/bin/env node
/**
 * Script Name: [SCRIPT_NAME]
 * Purpose: [DESCRIPTION]
 *
 * Usage:
 *   node script-template.mjs <REQUIRED_ARG> [--flag]
 *
 * Example:
 *   node script-template.mjs https://github.com/owner/repo/pull/123 --no-headless
 */

import { setTimeout } from 'timers/promises';
import { launchBrowser, needsAuth } from '../lib/browser.mjs';
import { notify } from '../lib/notify.mjs';
import { loadConfig } from '../lib/config.mjs';

async function main() {
  // Parse CLI arguments
  const args = process.argv.slice(2);
  const requiredArg = args[0];
  const headless = !args.includes('--no-headless');

  if (!requiredArg) {
    console.error('Usage: script-template <REQUIRED_ARG> [--no-headless] [--interval <ms>]');
    console.error('Example: script-template https://example.com');
    process.exit(1);
  }

  // Load configuration
  const config = await loadConfig();
  const intervalIndex = args.indexOf('--interval');
  const pollInterval = intervalIndex !== -1
    ? parseInt(args[intervalIndex + 1], 10)
    : config.polling.builds; // Adjust based on use case

  console.log(`🔍 Starting script...`);
  console.log(`   Polling every ${pollInterval / 1000}s\n`);

  // Launch browser
  const { browser, page } = await launchBrowser(headless);

  try {
    // Navigate to target URL
    await page.goto(requiredArg, { waitUntil: 'domcontentloaded', timeout: 60000 });

    // Check authentication
    if (await needsAuth(page)) {
      await notify('🔐 Auth Required', 'GitHub login needed');
      console.error('❌ Authentication required. Run: watch-pr-setup');
      process.exit(1);
    }

    // Main polling loop
    while (true) {
      await page.reload({ waitUntil: 'domcontentloaded' });

      // Your scraping logic here
      // Example: Check for a specific condition
      const condition = await page.locator('.target-selector').isVisible({ timeout: 1000 }).catch(() => false);

      if (condition) {
        await notify('✅ Success', 'Condition met');
        console.log('✅ Task complete!');
        break;
      }

      console.log(`⏳ Waiting... (${new Date().toLocaleTimeString()})`);
      await setTimeout(pollInterval);
    }
  } catch (err) {
    console.error('❌ Unexpected error:', err.message);
    await notify('❌ Script Error', err.message);
    throw err;
  } finally {
    await browser.close();
  }
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
