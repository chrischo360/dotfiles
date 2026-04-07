Router for sf-ui-checkout test environment setup.

Steps:

1. Verify we're in sf-ui-checkout repository:
   ```bash
   git remote -v | grep -q 'sf-ui-checkout' || { echo "❌ Not in sf-ui-checkout repository"; exit 1; }
   ```

2. Ask which environment via AskUserQuestion:
   "What kind of test environment do you need?"
   Options:
     - Code tests (test-env-code) - yarn install + GraphQL update. For unit tests.
     - E2E environment (test-env-e2e) - All 6 services via sf-ui-checkout-dev (webpack, SSH, realsync, render). For browser/integration testing.
     - Both - Run code env then E2E setup

3. Delegate:
   - Code: Skill("repos:sf-ui-checkout:test-env-code")
   - E2E: Skill("repos:sf-ui-checkout:test-env-e2e")
   - Both: Skill("repos:sf-ui-checkout:test-env-code") → Skill("repos:sf-ui-checkout:test-env-e2e")
