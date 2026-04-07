Set up the Playwright smoke test environment for sf-ui-web.

Playwright smoke tests run against a local production-mode server. Requires the dev cert to be trusted, Playwright browsers installed, and the app built and running.

Steps:

1. Verify we're in sf-ui-web repository:
   ```bash
   git remote -v | grep -q 'sf-ui-web' || { echo "❌ Not in sf-ui-web repository"; exit 1; }
   ```

2. Install the dev cert (one-time, macOS):
   ```bash
   CERT="./tools/framework/src/startRouter/proxies/_utils/loadDevelopmentCert/localdev.crt"
   security add-trusted-cert -d -r trustRoot -k ~/Library/Keychains/login.keychain-db "$CERT" \
     && echo "✓ Cert trusted" \
     || echo "⚠️  Cert may already be trusted or requires sudo — check Keychain Access"
   ```
   Note: If the above fails, open Keychain Access and manually add the cert from the path above.

3. Install Playwright browsers (one-time, or after Playwright version bump):
   ```bash
   yarn workspace @wayfair/sf-ui-core-funnel playwright:install
   ```
   This runs: `npx playwright install chromium`

4. Build the app in local-production mode:
   ```bash
   yarn build:local --filter=@wayfair/sf-ui-core-funnel
   ```
   This is a full production-mode build — takes several minutes.

5. Start the local production server (keep running in background/separate pane):
   ```bash
   yarn workspace @wayfair/sf-ui-core-funnel local-production:start
   ```
   Server must be running when tests execute.

6. Set up auth state (first time or after auth expires):
   The auth setup runs automatically as a Playwright project dependency before smoke tests.
   Test user: `qab2btest6@test.wayfair.com` / `dontChangeMe`
   Auth state saved to: `apps/core-funnel/playwright/.auth/authenticated-{locale}.json`

What this does:
- Trusts the local dev cert so HTTPS routes work correctly
- Installs Chromium browser for Playwright
- Builds core-funnel in production mode (required — smoke tests don't work against dev server)
- Starts the server (must remain running during test execution)

Error handling:
- Cert trust fails: Try `sudo security add-trusted-cert ...` or add manually via Keychain Access
- Build fails: Ensure `/test-env-code` was run first (yarn install + codegen + lib:build)
- Server won't start: Check port conflicts, kill existing processes on port 3000

Related commands:
- `/test-env-code` - Must run this first: yarn install + codegen + lib:build
- `/test-env-e2e-cypress` - Set up Cypress component test environment
- `/test-execute` - Run Playwright smoke tests: `yarn playwright:smoke` or `yarn playwright:dev` (UI mode)

Notes:
- Test files: `apps/core-funnel/playwright/tests/**/*.playwright.ts`
- 25+ smoke tests covering: homepage, PDP, browse, cart, checkout, header/footer, etc.
- Runs fully parallel (3 workers locally, 8 in CI)
- Screenshots on failure only; traces on first retry
- Node version required: 24.13.0 (check with `node --version`)
