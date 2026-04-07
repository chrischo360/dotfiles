Log a test session to per-repo memory and Claude project memory.

Called automatically after test-execute completes, or invoked manually to log a session.

Steps:

1. Gather context:
   ```bash
   REPO_NAME=$(basename $(git rev-parse --show-toplevel 2>/dev/null))
   DATE=$(date +%Y-%m-%d)
   MEMORY_FILE="~/dotfiles/claude/test-memory/${REPO_NAME}.md"
   ```

2. Ask user for session details via AskUserQuestion:
   "What were you testing?" (free text)
   "What was the outcome?" Options:
     - Pass
     - Pass (with flaky tests)
     - Fail
     - Inconclusive

3. Ask for notes via AskUserQuestion:
   "Any notes for next time?" (free text — edge cases, what to watch, follow-ups)

4. Build the log entry:
   ```markdown
   ## ${DATE}
   **What:** ${WHAT_TESTED}
   **Command:** ${COMMAND_USED}
   **Outcome:** ${OUTCOME}
   **Notes:** ${NOTES}
   ```

5. Write to per-repo memory file:
   - If ~/dotfiles/claude/test-memory/${REPO_NAME}.md does not exist:
     Create it with header: `# Test Memory: ${REPO_NAME}`
   - Append the new entry (most recent first, under the header)

6. Write to Claude project memory:
   - Save a project-type memory entry at:
     ~/.claude/projects/memory/test_${REPO_NAME}_latest.md
   - Content: last 3 sessions for this repo (for quick recall in future conversations)
   - Format:
     ```markdown
     ---
     name: Test memory for ${REPO_NAME}
     description: Recent test sessions for ${REPO_NAME} — what was tested, how, outcomes
     type: project
     ---

     Recent test sessions for ${REPO_NAME}:

     [last 3 entries from the per-repo file]
     ```

Notes:
- Command used is pulled from context if test-execute was just run; otherwise prompt for it
- Skip the AskUserQuestion prompts if user passes --skip-notes flag
- Overwrites the project memory file each time (keeps it current, not append)
