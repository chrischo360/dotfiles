---
description: Research and plan what tests to run and how
---
Research and plan what tests to run and how.

Detects repo-specific test-plan command. If none exists, researches the repo to understand test structure and surfaces a run plan.

Steps:

1. Check for repo-specific command:
   ```bash
   REPO_NAME=$(basename $(git rev-parse --show-toplevel 2>/dev/null))

   if [[ -f "~/dotfiles/claude/commands/repos/${REPO_NAME}/test-plan.md" ]]; then
     Skill(skill="repos:${REPO_NAME}:test-plan")
     exit 0
   fi
   ```

2. Check for prior test session memory:
   ```bash
   MEMORY_FILE="~/dotfiles/claude/test-memory/${REPO_NAME}.md"
   if [[ -f "$MEMORY_FILE" ]]; then
     echo "Prior test sessions found — incorporating into plan"
   fi
   ```
   If memory exists, include last 3 entries in the plan output under "Prior Sessions".

3. Spawn Explore agent to research test structure:
   - package.json scripts (test, test:unit, test:e2e, test:watch)
   - jest.config.js / vitest.config.ts / pytest.ini for test locations
   - CI configs (.github/workflows/, .buildkite/) for canonical test commands
   - Makefile test targets
   - Returns: what test frameworks are used, available test commands, recommended run order

3b. If local research is inconclusive (no test framework, script, or CI config found):

   a. Search Glean for enterprise knowledge about how this repo is tested:
      ```
      Skill(skill="glean-search:search", args="${REPO_NAME} how to run tests OR testing runbook")
      ```
      Look for: internal wikis, Confluence pages, runbooks, Slack threads mentioning test commands.

   b. Search Sourcegraph for test patterns in the codebase:
      ```
      mcp__sourcegraph__search(query="repo:${REPO_NAME} file:(test|spec|__tests__)", patternType="regexp")
      ```
      Look for: test file locations, test framework imports, CI step definitions.

   c. Combine findings from (a) and (b) with local research. Label the source of each finding:
      - [local] — found in repo files
      - [glean] — from enterprise knowledge base
      - [sourcegraph] — from cross-repo code search

4. Present findings as a plan — show what would be run and in what order, including any prior session context from step 2

5. Offer via AskUserQuestion:
   "Save this as a test plan for ${REPO_NAME}?"
   Options:
     - Yes - Spawn Plan agent to write repos/${REPO_NAME}/test-plan.md
     - No - Show plan only (user can run test-execute manually)

What this does:
- Output-focused: surfaces information, not execution
- Pairs with test-env (setup) and test-execute (run)
- Useful for understanding a new repo's test strategy
- Falls back to Glean + Sourcegraph MCP when local research is inconclusive
