Watch PR checks, auto-merge when all checks pass.

Wrapper for `dev :run pr:automerge` in sf-ui-web.

Steps:

1. Verify we're in sf-ui-web repository:
   ```bash
   git remote -v | grep -q 'sf-ui-web' || { echo "❌ Not in sf-ui-web repository"; exit 1; }
   ```

2. Run the pr:automerge script:
   ```bash
   dev :run pr:automerge
   ```

What this does:
- **Watch**: Uses `scout watch-builds` to monitor GitHub PR CI checks
  - Polls PR status every 30 seconds
  - Shows real-time check results
- **On Success**: Automatically merges PR with squash commit
  - Runs: `gh pr merge --auto --squash`
  - Desktop notification on merge
- **On Failure**: Stops and reports failure (no auto-fix)

Error handling:
- If not in sf-ui-web: Exits with error
- If no PR exists: Exits with error (must create PR first)
- If checks fail: Stops watching, reports failure
- Desktop notification on success/failure

Related commands:
- `/pr-submit` - Watch without auto-merge
- `/pr-diagnose` - Watch + diagnose failures with proposed fixes
- `/pr-check` - Just validation (no watch)

Notes:
- Requires existing PR before running
- Create PR with: `gh pr create`
- Uses squash merge (single commit on main)
- Watch runs until checks complete or fail
- Press Ctrl+C to stop watching
- PR must be approved before merge (GitHub setting)

Anti-Patterns to Avoid:
- Don't use for PRs requiring manual review - get approval first
- Don't interrupt watch - let it complete
- Don't use if you want rebase/merge commit - this uses squash
