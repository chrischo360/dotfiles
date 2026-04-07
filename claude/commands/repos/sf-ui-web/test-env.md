Router for sf-ui-web test environment setup.

Steps:

1. Verify we're in sf-ui-web repository:
   ```bash
   git remote -v | grep -q 'sf-ui-web' || { echo "❌ Not in sf-ui-web repository"; exit 1; }
   ```

2. Ask which environment via AskUserQuestion:
   "What kind of test environment do you need?"
   Options:
     - Code tests (test-env-code) - Install deps, codegen, lib:build. For unit/integration tests.
     - E2E environment (test-env-e2e) - Not currently applicable for sf-ui-web (tests run locally).
     - Both - Run code env setup

3. Delegate:
   - Code: Skill("repos:sf-ui-web:test-env-code")
   - Both: Skill("repos:sf-ui-web:test-env-code")
