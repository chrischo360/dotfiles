Router for sf-js-libraries test environment setup.

Steps:

1. Verify we're in sf-js-libraries repository:
   ```bash
   git remote -v | grep -q 'sf-js-libraries' || { echo "❌ Not in sf-js-libraries repository"; exit 1; }
   ```

2. Ask which environment via AskUserQuestion:
   "What kind of test environment do you need?"
   Options:
     - Code tests (test-env-code) - yarn install + library selection. For unit tests.
     - E2E environment (test-env-e2e) - Not applicable (use /prepublish to test in a consumer repo).
     - Both - Run code env setup

3. Delegate:
   - Code: Skill("repos:sf-js-libraries:test-env-code")
   - Both: Skill("repos:sf-js-libraries:test-env-code")
