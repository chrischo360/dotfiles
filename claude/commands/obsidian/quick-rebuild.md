# quick-rebuild

**Skill:** `repos:sf-ui-web:quick-rebuild`
**Type:** sf-ui-web Command

## Purpose

Fast rebuild: regenerate GraphQL types and build libraries.

## Uses

- dev CLI (`dev :run quick`) ← **wraps this script**
  - yarn gql:codegen
  - yarn lib:build

## Used By

- [[pr-cleanup]] (includes rebuild)
- User invoked after schema changes

## Workflow

1. Verify in sf-ui-web repository
2. Run codegen: `yarn gql:codegen`
3. Build libraries: `yarn lib:build`
4. Desktop notification on completion

## Error Handling

- If not in sf-ui-web: Exit with error
- If codegen fails: Stop before build
- If build fails: Show error details
- Desktop notification on completion

## When to Use

- After schema changes in block-builder-api
- After pulling main with GraphQL updates
- When you don't need full setup

## Notes

- Faster than full `/setup` (no install, no dev server)
- Takes ~1-2 minutes vs 5-10 for full setup
- Does not restart dev server

## Examples

**After schema change:**
```bash
# In block-builder-api: make schema changes
# In sf-ui-web:
/quick-rebuild
```

**After git pull:**
```bash
git pull origin main
/quick-rebuild  # If no dependency changes
```

## Related Commands

- [[pr-cleanup]] - Includes rebuild
- [[pr-check]] - Validation after rebuild

## Tags

#sf-ui-web #build #fast-workflow
