Build and prepare branch for PR by committing unstaged changes, syncing with main, rebuilding, and formatting.

Steps:

1. Get current branch name: `git branch --show-current`
   - Store this to return to later

2. Fetch latest from origin: `git fetch origin`
   - Check if local main is behind origin/main: `git rev-list HEAD..origin/main --count` (on main branch)
   - Check if feature branch is behind origin: `git rev-list HEAD..origin/<branch> --count` (if remote tracking exists)
   - If either is behind, inform user and proceed with pull

3. Check for unstaged changes: `git status --short`
   - If unstaged changes exist: `git add -A && git commit -m "wip"`

4. Update main branch:
   ```bash
   git checkout main
   git pull origin main
   yarn lib:build
   ```

5. Return to feature branch and sync with main:
   ```bash
   git checkout <branch-name>
   git pull origin main
   yarn lib:build
   ```

6. Install dependencies and generate code:
   ```bash
   yarn
   yarn gql:codegen
   ```

7. Format and lint:
   ```bash
   yarn format
   yarn biome lint
   yarn lint
   ```

8. Show final state:
   ```bash
   git status
   git diff
   ```

Error handling:
- Merge conflicts: Stop, inform user to resolve manually
- Build failures: Report error, ask how to proceed
- Lint errors: Show errors, ask if should continue

After cleanup:
- If formatter made changes: `git add -A && git commit -m "chore: format and lint"`
- Branch ready for `/pr` or `/pr-create`
