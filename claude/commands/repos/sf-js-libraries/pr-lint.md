Run format and lint validation for sf-js-libraries, with auto-fix on failure.

Fast validation step before full pr-check. Uses wayfair-workspaces to orchestrate Prettier and ESLint across monorepo packages.

Steps:

1. Verify we're in sf-js-libraries repository:
   ```bash
   git remote -v | grep -q 'sf-js-libraries' || { echo "Not in sf-js-libraries repository"; exit 1; }
   ```

2. Run format check:
   ```bash
   yarn format:check
   ```

3. If format check fails:
   - Run auto-fix:
     ```bash
     yarn format
     ```
   - Show the diff of what changed:
     ```bash
     git diff
     ```
   - Ask the user: "Format auto-fixed these issues. Want me to generate a commit command?"
   - If yes: generate a git commit command (do NOT run it — provide it for the user to copy/paste, per global rules)
   - If no: leave changes unstaged for manual review

4. Run lint:
   ```bash
   yarn lint
   ```

5. If lint fails with fixable errors:
   - Show the errors clearly
   - Attempt to fix them manually by reading the failing files and applying corrections
   - After fixing, re-run `yarn lint` to verify
   - Show the diff and ask the user if they want a commit command

6. If lint fails with unfixable errors:
   - Show the errors
   - Do NOT auto-fix

What this does:
- **Format Check**: Runs `wayfair-workspaces format --check` (Prettier) across all packages
- **Format Fix**: Runs `wayfair-workspaces format` (Prettier auto-fix)
- **Lint**: Runs `wayfair-workspaces lint` (ESLint) across all packages

Error handling:
- If not in sf-js-libraries: Exits with error message
- If format fails: Auto-fix with `yarn format`, then show diff and ask before committing
- If lint fails: Show errors, attempt manual fix for fixable issues

Related commands:
- `/pr-check` - Full validation suite
- `/pr-create` - Create PR with automated workflow

Notes:
- Faster than full validate (no build or test)
- Never commits without asking
- Uses Prettier for formatting, ESLint for linting (via wayfair-workspaces)
