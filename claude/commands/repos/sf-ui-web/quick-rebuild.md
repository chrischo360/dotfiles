Fast rebuild: regenerate GraphQL types and build libraries.

Wrapper for `dev :run quick` in sf-ui-web.

Steps:

1. Verify we're in sf-ui-web repository:
   ```bash
   git remote -v | grep -q 'sf-ui-web' || { echo "❌ Not in sf-ui-web repository"; exit 1; }
   ```

2. Run the quick rebuild script:
   ```bash
   dev :run quick
   ```

What this does:
- **Codegen**: Runs `yarn gql:codegen` to regenerate GraphQL types
- **Build**: Runs `yarn lib:build` to rebuild all libraries

Error handling:
- If not in sf-ui-web: Exits with error
- If codegen fails: Stops before build
- If build fails: Shows error details
- Desktop notification on completion

Related commands:
- `/pr-cleanup` - Includes rebuild as part of PR prep
- `/pr-check` - Validation after rebuild

Notes:
- Faster than full `/setup` (no install, no dev server)
- Run after schema changes in block-builder-api
- Run after pulling main with GraphQL updates
- Takes ~1-2 minutes vs 5-10 for full setup
- Does not restart dev server

Examples:
- After schema change:
  ```bash
  # In block-builder-api: make schema changes
  # In sf-ui-web:
  /quick-rebuild
  ```

- After git pull:
  ```bash
  git pull origin main
  /quick-rebuild  # If no dependency changes
  ```

Anti-Patterns to Avoid:
- Don't use after dependency changes - run `/setup` instead
- Don't use for first clone - run `/setup` instead
