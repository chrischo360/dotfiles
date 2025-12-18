#!/usr/bin/env node
import { setTimeout } from 'timers/promises';
import { launchBrowser, needsAuth } from '../lib/browser.mjs';
import { notify } from '../lib/notify.mjs';
import { loadConfig } from '../lib/config.mjs';

async function main() {
  const args = process.argv.slice(2);
  const deployUrl = args[0];
  const headless = !args.includes('--no-headless');

  if (!deployUrl) {
    console.error('Usage: deploy-tracker <DEPLOY_URL> [--env <staging|production>] [--no-headless] [--interval <ms>]');
    console.error('Example: deploy-tracker https://deploy.example.com/project/deployments');
    process.exit(1);
  }

  const config = await loadConfig();
  const intervalIndex = args.indexOf('--interval');
  const pollInterval = intervalIndex !== -1
    ? parseInt(args[intervalIndex + 1], 10)
    : config.polling.deploys;

  const envIndex = args.indexOf('--env');
  const targetEnv = envIndex !== -1 ? args[envIndex + 1] : null;
  const environments = targetEnv ? [targetEnv] : config.deploy_tracker.environments;

  console.log(`🚀 Watching deployments`);
  console.log(`   Environments: ${environments.join(', ')}`);
  console.log(`   Polling every ${pollInterval / 1000}s\n`);

  const { browser, page } = await launchBrowser(headless);

  const deploymentStates = new Map();

  try {
    await page.goto(deployUrl, { waitUntil: 'domcontentloaded', timeout: 60000 });

    if (await needsAuth(page)) {
      await notify('🔐 Auth Required', 'Deployment tracker login needed');
      console.error('❌ Authentication required. Please login manually.');
      process.exit(1);
    }

    while (true) {
      await page.reload({ waitUntil: 'domcontentloaded' });

      for (const env of environments) {
        // This is a generic implementation - adjust selectors based on actual deployment dashboard
        // Common patterns: look for env name + status indicators

        // Try common deployment status patterns
        const envSection = page.locator(`[data-environment="${env}"], .deployment-${env}, :has-text("${env}")`).first();
        const isVisible = await envSection.isVisible({ timeout: 1000 }).catch(() => false);

        if (!isVisible) {
          console.log(`⚠️  ${env}: Environment section not found`);
          continue;
        }

        // Look for common status indicators
        const isDeploying = await envSection.locator('.deploying, .in-progress, [data-status="deploying"]').isVisible({ timeout: 500 }).catch(() => false);
        const isSuccess = await envSection.locator('.success, .deployed, [data-status="success"]').isVisible({ timeout: 500 }).catch(() => false);
        const isFailed = await envSection.locator('.failed, .error, [data-status="failed"]').isVisible({ timeout: 500 }).catch(() => false);

        let currentState = 'unknown';
        if (isDeploying) {
          currentState = 'deploying';
        } else if (isSuccess) {
          currentState = 'success';
        } else if (isFailed) {
          currentState = 'failed';
        }

        const previousState = deploymentStates.get(env);

        // Notify on state change
        if (previousState && currentState !== previousState) {
          if (currentState === 'success') {
            await notify('✅ Deploy Complete', env, 'Deployment successful');
            console.log(`✅ ${env}: Deployment successful!`);
          } else if (currentState === 'failed') {
            await notify('❌ Deploy Failed', env, 'Deployment failed');
            console.log(`❌ ${env}: Deployment failed.`);
          } else if (currentState === 'deploying') {
            await notify('🚀 Deploying', env, 'Deployment started');
            console.log(`🚀 ${env}: Deployment started...`);
          }
        } else if (!previousState) {
          console.log(`📋 ${env}: Current status - ${currentState}`);
        } else {
          console.log(`⏳ ${env}: ${currentState} (${new Date().toLocaleTimeString()})`);
        }

        deploymentStates.set(env, currentState);
      }

      await setTimeout(pollInterval);
    }
  } finally {
    await browser.close();
  }
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
