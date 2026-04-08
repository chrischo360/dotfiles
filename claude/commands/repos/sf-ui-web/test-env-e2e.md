Set up the E2E/local dev environment for sf-ui-web.

Supports two modes: local dev environment (for manual browser testing during development) and Playwright/Cypress smoke test setup.

Steps:

1. Verify we're in sf-ui-web repository:
   ```bash
   git remote -v | grep -q 'sf-ui-web' || { echo "❌ Not in sf-ui-web repository"; exit 1; }
   ```

2. Ask which E2E environment via AskUserQuestion:
   "Which E2E environment do you need?"
   Options:
     - Local dev (manual testing) - Lint → build → yarn dev in core-funnel. For browser testing during development.
     - Playwright smoke tests - Build local-production server. For running automated smoke tests.
     - Cypress component tests - Start Storybook or dev server per lib/app.

3. Delegate:
   - Local dev: Skill("repos:sf-ui-web:test-env-dev")
   - Playwright: Skill("repos:sf-ui-web:test-env-e2e-playwright")
   - Cypress: Skill("repos:sf-ui-web:test-env-e2e-cypress")
