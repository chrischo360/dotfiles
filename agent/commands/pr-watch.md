---
description: Monitor GitHub PR CI checks in real-time via scout
---
Monitor GitHub PR CI checks in real-time.

Wrapper for `scout check` to watch PR status for current branch.

Steps:

1. Get PR URL for current branch:
   ```bash
   PR_URL=$(gh pr view --json url -q '.url' 2>/dev/null)
   ```

2. Verify PR exists:
   ```bash
   [ -z "$PR_URL" ] && echo "❌ No PR found for current branch. Create one first with: gh pr create" && exit 1
   ```

3. Watch PR checks:
   ```bash
   scout check "$PR_URL"
   ```

What this does:
- **Polls** GitHub PR status every 30 seconds
- **Displays** real-time status of all CI checks
- **Shows** check names, status (pending/success/failure), conclusion
- **Notifies** on completion (desktop notification)
- **Exits** when all checks complete or fail

Options:
- `--auto-merge`: Auto-merge PR when all checks pass
- `--once`: Check once and exit (no polling)

Examples:
- Basic watch:
  ```
  /pr-watch
  ```

- Watch with auto-merge:
  ```
  scout check "$PR_URL" --auto-merge
  ```

- Single check (no polling):
  ```
  scout check "$PR_URL" --once
  ```

Error handling:
- If no PR found: Shows error with instructions to create PR
- If checks fail: Shows failure details and exits
- Press Ctrl+C to stop watching

Related commands:
- `/pr-check` - Lightweight gh-native check monitor (no scout dependency)
- `/pr-dashboard` - View all PRs for a repo

Notes:
- Works for any GitHub repository
- Requires `gh` CLI authentication
- Requires `scout` CLI installed globally
- Auto-detects PR from current branch

Anti-Patterns to Avoid:
- Don't use before creating PR - create PR first
- Don't use for repos without CI checks - nothing to watch
