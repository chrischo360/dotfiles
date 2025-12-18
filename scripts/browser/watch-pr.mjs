#!/usr/bin/env node
import { setTimeout } from "timers/promises";
import { launchBrowser, needsAuth } from "./lib/browser.mjs";
import { notify } from "./lib/notify.mjs";
import { parsePrUrl } from "./lib/github.mjs";

const POLL_INTERVAL_MS = 10_000; // 10 seconds

async function main() {
  // Parse CLI arguments
  const args = process.argv.slice(2);
  const prUrl = args[0];
  const headless = args.includes("--headless");

  if (!prUrl || !prUrl.includes("github.com")) {
    console.error("Usage: watch-pr <PR_URL> [--headless]");
    console.error(
      "Example: watch-pr https://github.com/wayfair-shared/sf-ui-web/pull/15218",
    );
    process.exit(1);
  }

  // Extract PR number and repo from URL
  const { owner, repo, prNumber } = parsePrUrl(prUrl);

  console.log(`🔍 Watching PR #${prNumber} (${owner}/${repo})`);
  console.log(`   Mode: ${headless ? "headless" : "visible browser"}`);
  console.log(`   Polling every ${POLL_INTERVAL_MS / 1000}s\n`);

  // Launch browser with saved authentication
  const { browser, page } = await launchBrowser(headless);

  try {
    // Initial page load (only once)
    await page.goto(prUrl, { waitUntil: "domcontentloaded", timeout: 60000 });

    let isFirstIteration = true;
    while (true) {
      // Reload page on subsequent iterations (skip first time since we just loaded)
      if (!isFirstIteration) {
        if ((await page.url()) !== prUrl) {
          // If URL changed somehow, navigate back
          await page.goto(prUrl, {
            waitUntil: "domcontentloaded",
            timeout: 60000,
          });
        } else {
          // Fast reload using existing page
          await page.reload({ waitUntil: "domcontentloaded" });
        }
      }
      isFirstIteration = false;

      // Check if authentication is required
      if (await needsAuth(page)) {
        await notify(
          "🔐 Auth Required",
          `PR #${prNumber}`,
          "GitHub login needed",
        );
        console.error(
          "❌ GitHub authentication required. Please login manually.",
        );
        process.exit(1);
      }

      // Check if PR is already merged
      const isMerged = await page
        .locator(".State--merged")
        .isVisible({ timeout: 1000 })
        .catch(() => false);
      if (isMerged) {
        await notify("✅ PR Merged", `PR #${prNumber}`, `${owner}/${repo}`);
        console.log("✅ PR is merged! Stopping.");
        break;
      }

      // Check if PR is closed without merge
      const isClosed = await page
        .locator(".State--closed")
        .isVisible({ timeout: 1000 })
        .catch(() => false);
      if (isClosed) {
        await notify("❌ PR Closed", `PR #${prNumber}`, "Closed without merge");
        console.log("❌ PR is closed without merging. Stopping.");
        process.exit(1);
      }

      // Check for merge conflicts auto-resolve button
      const resolveButton = page.locator(
        'button:has-text("Resolve conflicts")',
      );
      const hasConflicts = await resolveButton
        .isVisible({ timeout: 1000 })
        .catch(() => false);

      if (hasConflicts) {
        console.log("🔧 Auto-resolving conflicts...");
        await notify(
          "🔧 Resolving Conflicts",
          `PR #${prNumber}`,
          `${owner}/${repo}`,
        );

        try {
          await resolveButton.click();
          await page.waitForTimeout(2000);

          // After resolving, check for update branch button
          const updateButton = page.locator('button:has-text("Update branch")');
          if (
            await updateButton.isVisible({ timeout: 1000 }).catch(() => false)
          ) {
            await updateButton.click();
            console.log("⬆  Updated branch");
            await notify(
              "⬆  Branch Updated",
              `PR #${prNumber}`,
              `${owner}/${repo}`,
            );
          }
        } catch (err) {
          console.error("❌ Failed to resolve conflicts:", err.message);
          await notify(
            "❌ Conflict Resolution Failed",
            `PR #${prNumber}`,
            err.message,
          );
          process.exit(1);
        }

        continue;
      }

      // Check for squash and merge button
      const squashButton = page.locator("button.merge-message").first();
      const canMerge = await squashButton
        .isEnabled({ timeout: 1000 })
        .catch(() => false);

      if (canMerge) {
        console.log("✅ Squash and merge is available!");
        await notify(
          "✅ Ready to Merge!",
          `PR #${prNumber}`,
          `${owner}/${repo} - Squash and merge available`,
        );
        console.log(
          "Stopping - merge button is ready. Visit PR to complete merge.",
        );
        break;
      }

      console.log(`⏳ Waiting... (${new Date().toLocaleTimeString()})`);
      await setTimeout(POLL_INTERVAL_MS);
    }
  } catch (err) {
    console.error("❌ Unexpected error:", err.message);
    await notify("❌ Script Error", `PR #${prNumber}`, err.message);
    throw err;
  } finally {
    await browser.close();
  }
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
