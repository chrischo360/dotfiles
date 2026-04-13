Run format and lint validation for sf-ui-web, with auto-fix on failure.

Fast validation step before full pr-check. Matches Buildkite CI lint checks.

Steps:

1. Verify we're in sf-ui-web repository:
   ```bash
   git remote -v | grep -q 'sf-ui-web' || { echo "Not in sf-ui-web repository"; exit 1; }
   ```

2. Run format:
   ```bash
   yarn format
   ```

3. Run lint (biome + eslint):
   ```bash
   yarn biome:lint
   yarn lint
   ```

4. If biome lint fails with fixable errors:
   - Run auto-fix:
     ```bash
     yarn biome:lint:fix
     ```
   - Show the diff of what changed:
     ```bash
     git diff
     ```
   - Ask the user: "Biome auto-fixed these issues. Want me to generate a commit command?"
   - If yes: generate a git commit command (do NOT run it — provide it for the user to copy/paste, per global rules)
   - If no: leave changes unstaged for manual review

5. If biome lint fails with unfixable errors:
   - Show the errors clearly
   - Attempt to fix them manually by reading the failing files and applying corrections
   - After fixing, re-run `yarn biome:lint` to verify
   - Show the diff and ask the user if they want a commit command

6. If eslint fails:
   - Show the errors
   - Do NOT auto-fix (eslint fixes are less predictable)

What this does:
- **Format**: Runs Biome formatter via `yarn format`
- **Biome Lint**: Runs `biome ci --diagnostic-level=error` (matches Buildkite CI)
- **Biome Fix**: On failure, runs `biome lint --write --unsafe` + `yarn format`
- **ESLint**: Runs ESLint via `yarn lint`
- **Manual Fix**: For unfixable biome errors, reads files and applies corrections

Error handling:
- If not in sf-ui-web: Exits with error message
- If biome lint fails: Auto-fix, then show diff and ask before committing
- If eslint fails: Show errors only (no auto-fix)

Related commands:
- `/pr-check` - Full validation suite (typecheck, build, test)
- `/pr-build` - Commit + sync main + rebuild before validation
- `/pr-create` - Create PR with automated workflow

Notes:
- Faster than pr-check (no typecheck, build, test)
- Matches Buildkite CI lint validation
- Never commits without asking
- Safe fixes only (biome --write --unsafe is still scoped to lint rules)
