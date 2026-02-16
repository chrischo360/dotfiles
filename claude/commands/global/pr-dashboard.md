Display PR dashboard for a repository showing status of all open PRs.

Wrapper for `scout pr-dashboard` to view all PRs in a repository.

Steps:

1. Determine repository:
   - If in a git repo, auto-detect from remote
   - Otherwise, ask user for repo (format: `owner/repo`)

2. Run scout pr-dashboard:
   ```bash
   scout pr-dashboard <owner/repo>
   ```

What this does:
- **Fetches** all open PRs for the repository
- **Displays** PR dashboard with:
  - PR number and title
  - Author
  - Status (draft, ready, approved, changes requested)
  - CI check status (pending, passing, failing)
  - Review status
  - Days since last update
- **Sorts** by last updated (most recent first)

Examples:
- Auto-detect from current repo:
  ```bash
  # In sf-ui-web directory
  /pr-dashboard
  # Uses: wayfair-shared/sf-ui-web
  ```

- Specify repository:
  ```bash
  scout pr-dashboard wayfair-shared/sf-ui-web
  ```

- View PRs for different repo:
  ```bash
  scout pr-dashboard wayfair/php
  ```

Error handling:
- If not in git repo and no repo provided: Prompts for repository
- If invalid repo format: Shows error
- If no access to repo: Shows authentication error

Related commands:
- `/pr-watch` - Monitor specific PR checks
- `/pr-template` - Generate PR description

Notes:
- Works for any GitHub repository you have access to
- Requires `gh` CLI authentication
- Requires `scout` CLI installed globally
- Useful for team PR review queue
- Can identify stale PRs or blocked PRs

Anti-Patterns to Avoid:
- Don't use for repos with hundreds of PRs - scout may timeout
- Don't confuse with `/pr-watch` - this is for viewing all PRs, not monitoring one
