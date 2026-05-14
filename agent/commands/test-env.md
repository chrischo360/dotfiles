---
description: Router for test environment setup — delegates to test-env-code or test-env-e2e
---
Router for test environment setup. Asks which kind of environment is needed, then delegates to test-env-code or test-env-e2e.

Steps:

1. Check for repo-specific command:
   ```bash
   REPO_NAME=$(basename $(git rev-parse --show-toplevel 2>/dev/null))

   if [[ -f "~/dotfiles/claude/commands/repos/${REPO_NAME}/test-env.md" ]]; then
     Skill(skill="repos:${REPO_NAME}:test-env")
     exit 0
   fi
   ```

2. Ask which environment via AskUserQuestion:
   "What kind of test environment do you need?"
   Options:
     - Code tests (test-env-code) - Install deps, compile, build artifacts. For unit/integration tests.
     - E2E environment (test-env-e2e) - Start services, SSH tunnels, browsers, sync. For end-to-end tests.
     - Both - Run test-env-code then test-env-e2e in sequence

3. Delegate:
   - Code: Skill("global:test-env-code")
   - E2E: Skill("global:test-env-e2e")
   - Both: Skill("global:test-env-code") → Skill("global:test-env-e2e")

Notes:
- If no repo-specific command exists, delegates to global test-env-code or test-env-e2e
- Those global commands will research the repo if no repo-specific variant exists either
