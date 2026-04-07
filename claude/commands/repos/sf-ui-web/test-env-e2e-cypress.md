Set up the Cypress component test environment for sf-ui-web.

Cypress component tests run across 15+ libraries and apps. Each target needs its component server (usually Storybook at localhost:6006 or a local dev server at localhost:3000).

Steps:

1. Verify we're in sf-ui-web repository:
   ```bash
   git remote -v | grep -q 'sf-ui-web' || { echo "❌ Not in sf-ui-web repository"; exit 1; }
   ```

2. Ensure libraries are built (Cypress tests import from built lib artifacts):
   ```bash
   yarn lib:build
   ```
   Skip if already done via `/test-env-code`.

3. Ask what to test via AskUserQuestion:
   "Which Cypress target?"
   Options:
     - All (via turbo) - `yarn cypress:component` from repo root — runs all lib/app cypress suites
     - Specific library - prompt for library name (e.g. `listing-card`, `browse-ui`, `minicart`)
     - Specific app - prompt for app name (e.g. `core-funnel`, `platform-capabilities`, `sf-ui-homepage`)

4a. For all (turbo):
   No additional server setup needed — turbo handles per-package servers.
   ```bash
   yarn build:cypress   # build if needed
   yarn cypress:component
   ```

4b. For a specific library:
   Most libs use Storybook on `localhost:6006`. Start it in a separate pane:
   ```bash
   cd libs/<library-name>
   yarn storybook        # or check package.json for the exact dev command
   ```
   Then open Cypress:
   ```bash
   cd libs/<library-name>
   yarn cypress open --component
   ```

4c. For a specific app:
   - `platform-capabilities`: needs `localhost:3000` — run `yarn dev` in that app directory
   - `core-funnel` smoke via Cypress: uses `localhost:6006` (Storybook) for component tests
   ```bash
   cd apps/<app-name>
   yarn cypress open --component
   ```

What this does:
- Routes to the right Cypress target (whole repo via turbo, or a single lib/app)
- For libs: Storybook is typically the component server at localhost:6006
- For apps: dev server at localhost:3000

Error handling:
- `DOCKER_CYPRESS_BASE_URL` env var overrides base URL — used in CI, not needed locally
- Cypress binary missing: `npx cypress install`
- Storybook won't start: Check for port conflicts on 6006

Related commands:
- `/test-env-code` - Run first: yarn install + codegen + lib:build
- `/test-env-e2e-playwright` - Set up Playwright smoke test environment
- `/test-execute` - Run Cypress tests

Notes:
- Cypress configs: `apps/core-funnel/cypress.config.ts`, `libs/*/cypress.config.ts` (15+ files)
- Base URL defaults: `localhost:6006` (libs via Storybook), `localhost:3000` (apps)
- CI uses Xvfb virtual displays (`:105`–`:108`) — not needed locally
- Test files follow pattern: `cypress/e2e/**/*.cy.ts` or `cypress/component/**/*.cy.ts`
- `chromeWebSecurity: false` is set in most configs
