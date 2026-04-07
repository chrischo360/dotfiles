Router for block-builder-api test environment setup.

Steps:

1. Verify we're in block-builder-api repository:
   ```bash
   git remote -v | grep -q 'block-builder-api' || { echo "❌ Not in block-builder-api repository"; exit 1; }
   ```

2. Ask which environment via AskUserQuestion:
   "What kind of test environment do you need?"
   Options:
     - Code tests (test-env-code) - Spotless format fix + Maven compile. For unit/integration tests.
     - E2E environment (test-env-e2e) - Not applicable (block-builder-api tests run in-process via Maven).
     - Both - Run code env setup

3. Delegate:
   - Code: Skill("repos:block-builder-api:test-env-code")
   - Both: Skill("repos:block-builder-api:test-env-code")
