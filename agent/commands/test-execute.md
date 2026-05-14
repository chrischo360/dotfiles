---
description: Execute tests for the current repository
---
Execute tests for the current repository.

Detects repo-specific test-execute command. If none exists, uses test-plan findings or researches how to run tests.

Steps:

1. Check for repo-specific command:
   ```bash
   REPO_NAME=$(basename $(git rev-parse --show-toplevel 2>/dev/null))

   if [[ -f "~/dotfiles/claude/commands/repos/${REPO_NAME}/test-execute.md" ]]; then
     Skill(skill="repos:${REPO_NAME}:test-execute")
     exit 0
   fi
   ```

2. Check if test-plan has already been run / findings are available in context.
   If not: spawn lightweight Explore agent to find the test command:
   - package.json `test` script
   - jest.config / vitest.config presence
   - Makefile `test` target
   - CI config canonical test step

3. Show what will be run. Ask for confirmation via AskUserQuestion:
   "Run tests for ${REPO_NAME}?"
   Options:
     - Yes - Execute the test command
     - Yes, watch mode - Run in watch mode if available
     - Create command - Spawn Plan agent to write repos/${REPO_NAME}/test-execute.md
     - No - Exit

4. On failure: show output, ask how to proceed (don't auto-retry)

5. After run completes (pass or fail): invoke test-log to record the session:
   ```
   Skill(skill="global:test-log")
   ```
   Pass the command used and outcome as context so test-log doesn't need to re-ask.

What this does:
- Always shows the command before running it
- Never runs blindly — surfaces what it found
- Pairs with test-env (ensure environment is set up first)
- On failure: report immediately and wait for user direction
- Always logs to per-repo memory after completing
