#!/usr/bin/env node

/**
 * Helper script to manage Glean MCP OAuth tokens for Pi
 *
 * Usage:
 *   node pi-glean-oauth.mjs          # Refresh existing token
 *   node pi-glean-oauth.mjs --reset  # Force new OAuth flow
 */

import fs from 'fs';
import path from 'path';
import os from 'os';
import { exec } from 'child_process';
import { promisify } from 'util';

const execAsync = promisify(exec);

const TOKEN_FILE = path.join(os.homedir(), '.pi', 'agent', 'glean-oauth.json');
const GLEAN_INSTANCE = process.env.GLEAN_INSTANCE || process.env.GLEAN_SUBDOMAIN || 'wayfair';
const SERVER_URL = `https://${GLEAN_INSTANCE}-be.glean.com/mcp/default`;

async function loadTokens() {
  try {
    if (fs.existsSync(TOKEN_FILE)) {
      const data = fs.readFileSync(TOKEN_FILE, 'utf-8');
      return JSON.parse(data);
    }
  } catch (err) {
    console.error('Failed to load tokens:', err.message);
  }
  return null;
}

function saveTokens(tokens) {
  const dir = path.dirname(TOKEN_FILE);
  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true });
  }
  fs.writeFileSync(TOKEN_FILE, JSON.stringify(tokens, null, 2));
  console.log(`✓ Tokens saved to ${TOKEN_FILE}`);
}

async function initiateOAuthDeviceFlow() {
  console.log('\n=== Glean OAuth Device Flow ===\n');

  // Step 1: Get device code
  const deviceAuthUrl = `${SERVER_URL}/oauth/device/code`;
  const deviceBody = JSON.stringify({
    client_name: "Pi Coding Agent (glean_default)",
    scope: [
      "activity", "agents", "announcements", "answers", "chat", "collections",
      "documents", "email", "entities", "feed", "feedback", "insights", "mcp",
      "offline_access", "openid", "people", "pins", "search", "shortcuts",
      "summarize", "tools"
    ]
  });

  const { stdout: deviceStdout } = await execAsync(
    `curl --silent --show-error --request POST --header "Content-Type: application/json" --data '${deviceBody}' "${deviceAuthUrl}"`
  );

  const deviceData = JSON.parse(deviceStdout);

  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  console.log(`Please visit: ${deviceData.verification_uri}`);
  console.log(`Enter code: ${deviceData.user_code}`);
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  console.log('Waiting for you to authorize...\n');

  // Step 2: Poll for token
  const tokenUrl = `${SERVER_URL}/oauth/token`;
  const pollInterval = (deviceData.interval || 5) * 1000;
  const expiresIn = (deviceData.expires_in || 600) * 1000;
  const deadline = Date.now() + expiresIn;

  while (Date.now() < deadline) {
    await new Promise(resolve => setTimeout(resolve, pollInterval));

    const tokenBody = JSON.stringify({
      grant_type: "urn:ietf:params:oauth:grant-type:device_code",
      device_code: deviceData.device_code,
      client_id: deviceData.client_id
    });

    const { stdout: tokenStdout } = await execAsync(
      `curl --silent --show-error --request POST --header "Content-Type: application/json" --data '${tokenBody}' "${tokenUrl}"`
    );

    const tokenData = JSON.parse(tokenStdout);

    if (tokenData.error) {
      if (tokenData.error === 'authorization_pending') {
        process.stdout.write('.');
        continue;
      } else if (tokenData.error === 'slow_down') {
        await new Promise(resolve => setTimeout(resolve, 5000));
        continue;
      } else {
        throw new Error(`OAuth error: ${tokenData.error} - ${tokenData.error_description}`);
      }
    }

    if (tokenData.access_token) {
      console.log('\n\n✓ OAuth authorization successful!');

      const tokens = {
        accessToken: tokenData.access_token,
        refreshToken: tokenData.refresh_token,
        expiresAt: Date.now() + (tokenData.expires_in || 3600) * 1000,
        serverUrl: SERVER_URL,
        clientId: deviceData.client_id
      };

      saveTokens(tokens);
      return tokens;
    }
  }

  throw new Error('OAuth device flow timed out');
}

async function refreshAccessToken(tokens) {
  console.log('Refreshing Glean OAuth token...');

  const tokenUrl = `${tokens.serverUrl}/oauth/token`;
  const refreshBody = JSON.stringify({
    grant_type: "refresh_token",
    refresh_token: tokens.refreshToken,
    client_id: tokens.clientId
  });

  const { stdout } = await execAsync(
    `curl --silent --show-error --request POST --header "Content-Type: application/json" --data '${refreshBody}' "${tokenUrl}"`
  );

  const tokenData = JSON.parse(stdout);

  if (tokenData.error) {
    throw new Error(`Token refresh error: ${tokenData.error} - ${tokenData.error_description}`);
  }

  const newTokens = {
    accessToken: tokenData.access_token,
    refreshToken: tokenData.refresh_token || tokens.refreshToken,
    expiresAt: Date.now() + (tokenData.expires_in || 3600) * 1000,
    serverUrl: tokens.serverUrl,
    clientId: tokens.clientId
  };

  saveTokens(newTokens);
  console.log('✓ Token refreshed successfully');
  return newTokens;
}

async function main() {
  const args = process.argv.slice(2);
  const reset = args.includes('--reset');

  if (reset) {
    console.log('Resetting tokens...');
    if (fs.existsSync(TOKEN_FILE)) {
      fs.unlinkSync(TOKEN_FILE);
      console.log(`✓ Deleted ${TOKEN_FILE}`);
    }
  }

  let tokens = loadTokens();

  if (!tokens || tokens.serverUrl !== SERVER_URL) {
    console.log('No valid tokens found, starting OAuth flow...');
    tokens = await initiateOAuthDeviceFlow();
  } else if (tokens.expiresAt < Date.now() + 5 * 60 * 1000) {
    console.log('Token expired or expiring soon...');
    tokens = await refreshAccessToken(tokens);
  } else {
    const expiresInMinutes = Math.floor((tokens.expiresAt - Date.now()) / 60000);
    console.log(`✓ Token is still valid (expires in ${expiresInMinutes} minutes)`);
  }

  console.log(`\nToken details:`);
  console.log(`  Server: ${tokens.serverUrl}`);
  console.log(`  Client ID: ${tokens.clientId}`);
  console.log(`  Expires: ${new Date(tokens.expiresAt).toLocaleString()}`);
}

main().catch(err => {
  console.error('\n❌ Error:', err.message);
  process.exit(1);
});
