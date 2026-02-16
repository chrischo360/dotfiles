# pr-check

**Skill:** `repos:sf-ui-web:pr-check`
**Type:** sf-ui-web Command

## Purpose

Run full pre-PR validation suite (format, lint, typecheck, build, test).

## Uses

- dev CLI (`dev :run pr:check`) ← **wraps this script**
  - yarn format
  - yarn lint
  - yarn type-check
  - yarn lib:build
  - yarn test

## Used By

- [[pr-create]] ← **optionally invoked**
- [[pr-submit]] (includes validation)
- [[pr-diagnose]] (for testing proposed fixes)
- User invoked manually

## Workflow

1. Verify in sf-ui-web repository
2. Run dev :run pr:check
   - Format code
   - Lint code
   - Type check
   - Build libraries
   - Run tests
3. Desktop notification on completion

## Error Handling

- If not in sf-ui-web: Exit with error
- If any step fails: Show which step failed
- Desktop notification on success/failure

## Related Commands

- [[pr-cleanup]] - Prepare before running checks
- [[pr-submit]] - Checks + watch
- [[pr-diagnose]] - Use to test fixes

## Tags

#sf-ui-web #validation #reusable-component
