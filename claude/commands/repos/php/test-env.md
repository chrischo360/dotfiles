Router for PHP monorepo test environment setup.

Steps:

1. Verify we're in the PHP repository:
   ```bash
   git remote -v | grep -q 'php' || { echo "❌ Not in PHP repository"; exit 1; }
   ```

2. Ask which environment via AskUserQuestion:
   "What kind of test environment do you need?"
   Options:
     - Code tests (test-env-code) - Verify PHP toolchain, Composer install. For PHPUnit and code style.
     - E2E environment (test-env-e2e) - SSH tunnel + realsync to dev server. For full stack testing.
     - Both - Run code env then E2E setup

3. Delegate:
   - Code: Skill("repos:php:test-env-code")
   - E2E: Skill("repos:php:test-env-e2e")
   - Both: Skill("repos:php:test-env-code") → Skill("repos:php:test-env-e2e")
