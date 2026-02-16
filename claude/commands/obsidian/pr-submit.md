# pr-submit

**Skill:** `repos:sf-ui-web:pr-submit`
**Type:** sf-ui-web Command

## Purpose

Run full validation suite then watch PR CI checks.

## Uses

- dev CLI (`dev :run pr:submit`) ← **wraps this script**
  - Runs [[pr-check]] validation steps
  - Uses scout watch-builds (same as [[pr-watch]])

## Used By

- User invoked for validation + monitoring

## Workflow

```
1. Verify in sf-ui-web repository

2. Run validation suite
   - Format (yarn format)
   - Lint (yarn lint)
   - Typecheck (yarn type-check)
   - Build (yarn lib:build)
   - Test (yarn test)

3. Watch PR checks
   - Poll PR status every 30 seconds
   - Show real-time check results
   - Desktop notifications on completion
```

## Error Handling

- If not in sf-ui-web: Exit with error
- If no PR exists: Skip watch step (validation still runs)
- If validation fails: Run AI diagnosis
- Desktop notification on success/failure

## Related Commands

- [[pr-check]] - Validation portion
- [[pr-watch]] - Monitoring portion
- [[pr-diagnose]] - Adds failure diagnosis
- [[pr-automerge]] - Adds auto-merge
- [[pr-cleanup]] - Preparation step

## Tags

#sf-ui-web #pr-workflow #validation #monitoring #composite-command
