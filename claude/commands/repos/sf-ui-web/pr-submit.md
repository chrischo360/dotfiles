Run full validation suite then watch PR CI checks.

Wrapper for `dev :run pr:submit` in sf-ui-web.

Steps:

1. Verify we're in sf-ui-web repository:
   ```bash
   git remote -v | grep -q 'sf-ui-web' || { echo "❌ Not in sf-ui-web repository"; exit 1; }
   ```

2. Run the pr:submit script:
   ```bash
   dev :run pr:submit
   ```

What this does:
- **Format**: Runs `yarn format` to auto-format code
- **Lint**: Runs `yarn lint` to check code quality
- **Typecheck**: Runs `yarn type-check` to verify TypeScript types
- **Build**: Runs `yarn lib:build` to build all libraries
- **Test**: Runs `yarn test` to execute test suite
- **Watch**: Uses `scout watch-builds` to monitor GitHub PR CI checks
  - Polls PR status every 30 seconds
  - Shows real-time check results
  - Desktop notifications on completion

Error handling:
- If not in sf-ui-web: Exits with error
- If no PR exists: Skips watch step (validation still runs)
- If validation fails: Runs AI diagnosis to identify root cause
- Desktop notification on success/failure

Related commands:
- `/pr-check` - Just run validation suite (no watch)
- `/pr-diagnose` - Watch + diagnose failures with proposed fixes
- `/pr-automerge` - Watch + auto-merge on success
- `/pr-cleanup` - Prepare branch before validation

Notes:
- Requires existing PR for watch step
- Create PR first with: `gh pr create`
- Watch runs until all checks complete
- Press Ctrl+C to stop watching
