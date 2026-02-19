Run full pre-PR validation suite (format, lint, typecheck, build, test).

Wrapper for `dev :run pr:check` in sf-ui-web.

Steps:

1. Verify we're in sf-ui-web repository:
   ```bash
   git remote -v | grep -q 'sf-ui-web' || { echo "❌ Not in sf-ui-web repository"; exit 1; }
   ```

2. Run the pr:check script:
   ```bash
   dev :run pr:check
   ```

What this does:
- **Format**: Runs `yarn format` to auto-format code
- **Lint**: Runs `yarn lint` to check code quality
- **Typecheck**: Runs `yarn type-check` to verify TypeScript types
- **Build**: Runs `yarn lib:build` to build all libraries
- **Test**: Runs `yarn test` to execute test suite

The dev CLI provides step-by-step progress with logging. If any step fails, check the log file at `~/.dev/logs/sf-ui-web-pr:check-<timestamp>.log` for details.

Error handling:
- If not in sf-ui-web: Exits with error message
- If any step fails: Shows which step failed and the error
- Desktop notification on completion (success/failure)

Related commands:
- `/pr-build` - Commit changes + sync with main before running checks
- `/pr-push` - Push changes + watch PR CI status + diagnose failures
- `/pr-create` - Create PR with automated workflow

Notes:
- This command runs the same validation suite that CI runs
- Recommended to run before creating a PR
- Faster than waiting for CI feedback
- Logs saved to `~/.dev/logs/sf-ui-web-pr:check-<timestamp>.log` for debugging
