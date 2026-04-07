Execute tests for sf-ui-web.

Steps:

1. Verify we're in sf-ui-web repository:
   ```bash
   git remote -v | grep -q 'sf-ui-web' || { echo "❌ Not in sf-ui-web repository"; exit 1; }
   ```

2. Ask what to run via AskUserQuestion:
   "Which tests?"
   Options:
     - All tests - `yarn test`
     - Watch mode - `yarn test --watch`
     - Specific file - prompt for path, then `yarn test <path>`
     - Changed files only - `yarn test --onlyChanged`

3. Run the selected command.

4. On failure: show output, ask how to proceed (don't auto-retry).

5. After completion: invoke `global:test-log` to record the session.

What this does:
- Runs Jest test suite
- Supports targeting specific files or only changed files
- Watch mode for iterative development

Error handling:
- If not in sf-ui-web: Exits with error message
- If tests fail: Shows failure summary, waits for direction
- Flaky tests: Note in test-log with "Pass (flaky)" outcome

Related commands:
- `/test-env` - Set up environment before running
- `/pr-check` - Full suite (format + lint + typecheck + build + test)

Notes:
- Ensure `/test-env` has been run if node_modules or lib artifacts are stale
- `--onlyChanged` is fastest for iterative work on a feature branch
