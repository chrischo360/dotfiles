---
description: Parent test command — menu-driven entry point for test-env, test-plan, test-execute
---
Parent test command. Presents a menu to run test-env, test-plan, or test-execute — or runs the full workflow in sequence.

Also checks for a repo-specific test.md to delegate to.

Steps:

1. Check for repo-specific command:
   ```bash
   REPO_NAME=$(basename $(git rev-parse --show-toplevel 2>/dev/null))

   if [[ -f "~/dotfiles/claude/commands/repos/${REPO_NAME}/test.md" ]]; then
     Skill(skill="repos:${REPO_NAME}:test")
     exit 0
   fi
   ```

2. Present menu via AskUserQuestion:
   "What would you like to do?"
   Options:
     - Full workflow - Run test-env → test-plan → test-execute in sequence
     - Set up environment (test-env)
     - Plan tests (test-plan)
     - Run tests (test-execute)

3. Invoke the selected skill(s):
   - Full workflow: Skill("global:test-env") → Skill("global:test-plan") → Skill("global:test-execute")
   - Single: invoke the matching global skill

Notes:
- Entry point for users who don't know which sub-command they need
- Repo-specific test.md can override the entire flow
- Falls back to the global sub-commands if no repo-specific command exists
