Set up the local dev environment for sf-ui-web manual browser testing.

Runs lint → build → yarn dev in apps/core-funnel. Use this for manual browser verification during development.

Steps:

1. Verify we're in sf-ui-web repository:
   ```bash
   git remote -v | grep -q 'sf-ui-web' || { echo "❌ Not in sf-ui-web repository"; exit 1; }
   ```

2. Run lint (must pass before starting dev server):
   ```bash
   yarn biome lint
   yarn lint
   ```
   Fix any errors before proceeding.

3. Build touched packages (use turbo filter for speed, fall back to full lib:build):
   ```bash
   # Preferred: build only packages you've changed
   yarn turbo run build --filter=...[HEAD]

   # Fallback: build all libraries
   yarn lib:build
   ```
   If unsure which packages were touched, use the fallback.

4. Start the dev server in apps/core-funnel (keep running in a separate pane):
   ```bash
   cd apps/core-funnel
   yarn dev
   ```
   Server starts with `CONFIGS_ENV=development` on the default Next.js port.

What this does:
- **Lint**: Catches errors early — don't start the dev server with broken code
- **Build**: Ensures internal library changes are compiled before the app loads them
- **Dev server**: Starts the core-funnel app in development mode for browser testing

Error handling:
- Lint fails: Fix errors before proceeding — don't skip
- Build fails: Check turbo output for which package failed; may need `yarn install` first
- Dev server crashes: Check for port conflicts or missing env vars

Related commands:
- `/test-env-code` - yarn install + codegen + lib:build (run before this if starting fresh)
- `/test-env-e2e-playwright` - For automated Playwright smoke tests instead
- `/pr-lint` - Same lint step, standalone

Notes:
- `yarn dev` uses `NODE_OPTIONS=--max-old-space-size=12288` — needs sufficient memory
- For a full fresh setup: run `/test-env-code` first, then this command
- `cd apps/core-funnel` is required — `yarn dev` must run from that directory
