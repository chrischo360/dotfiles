Run format and lint validation for sf-ui-web.

Wrapper for `dev :run pr:lint` in sf-ui-web. Fast validation step before full pr-check.

Steps:

1. Verify we're in sf-ui-web repository:
   ```bash
   git remote -v | grep -q 'sf-ui-web' || { echo "❌ Not in sf-ui-web repository"; exit 1; }
   ```

2. Run format:
   ```bash
   yarn format
   ```

3. Run lint (biome + eslint):
   ```bash
   yarn biome lint
   yarn lint
   ```

What this does:
- **Format**: Runs Prettier via `yarn format`
- **Biome Lint**: Runs Biome linter
- **ESLint**: Runs ESLint via `yarn lint`

Error handling:
- If not in sf-ui-web: Exits with error message
- If lint fails: Shows errors and exits with non-zero code

Related commands:
- `/pr-check` - Full validation suite (typecheck, build, test)
- `/pr-build` - Commit + sync main + rebuild before validation
- `/pr-create` - Create PR with automated workflow

Notes:
- Faster than pr-check (no typecheck, build, test)
- Matches Buildkite dependencies validation
- Recommended for quick validation loops
