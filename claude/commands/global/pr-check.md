Monitor GitHub PR CI checks using native `gh` CLI.

Lightweight wrapper around `gh pr checks` for real-time CI status monitoring.

Steps:

1. Verify gh CLI is authenticated:
   ```bash
   gh auth status &>/dev/null || { echo "❌ gh CLI is not authenticated. Run: gh auth login"; exit 1; }
   ```

2. Get PR number for current branch:
   ```bash
   PR_NUM=$(gh pr view --json number -q '.number' 2>/dev/null)
   [ -z "$PR_NUM" ] && echo "❌ No PR found for current branch. Create one first." && exit 1
   ```

3. Watch PR checks:
   ```bash
   gh pr checks --watch
   ```

Options:
- `--watch` (default): Poll and display checks in real-time until completion
- `--once`: Check once without polling and exit
- `--interval <seconds>`: Custom polling interval (default 10 seconds)
- `--fail-fast`: Exit immediately on first check failure
- `--required`: Show only required checks
- `--web`: Open checks in browser

Examples:
- Watch checks in real-time:
  ```
  /pr-check
  ```

- Single check without polling:
  ```
  /pr-check --once
  ```

- Watch with custom 5-second interval:
  ```
  /pr-check --interval 5
  ```

- Exit on first failure:
  ```
  /pr-check --fail-fast
  ```

What this does:
- **Detects** current PR from branch name
- **Polls** GitHub PR status (10s default interval, configurable)
- **Displays** real-time check status with emojis and timestamps
- **Shows** check names, states (pending/success/failure)
- **Exits** when all checks complete or fail
- **Supports** press Ctrl+C to stop watching

Exit codes:
- 0: All checks passed or completed
- 8: Checks still pending (when using `--once`)
- 1: Error or checks failed

Error handling:
- If no PR found: Shows error and exits
- If gh not authenticated: Shows auth instructions
- If no checks exist: Reports no checks found
- Press Ctrl+C to stop watching at any time

Related commands:
- `/pr-watch` - Enhanced wrapper with auto-merge and notifications (requires scout)
- `/pr-dashboard` - View all open PRs for a repository
- `/global:pr-create` - Create a new PR

Notes:
- Works for any GitHub repository
- Requires `gh` CLI (no external dependencies like scout)
- Auto-detects PR from current branch
- Uses GitHub API via gh CLI

Anti-Patterns to Avoid:
- Don't use before creating PR - create PR first
- Don't use for repos without CI checks configured
