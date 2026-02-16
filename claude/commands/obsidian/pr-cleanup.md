# pr-cleanup

**Skill:** `repos:sf-ui-web:pr-cleanup`
**Type:** sf-ui-web Command

## Purpose

Prepare branch for PR by committing unstaged changes, syncing with main, rebuilding, and formatting.

## Uses

- git (commit, fetch, merge, checkout)
- yarn (install, codegen, build, format, lint)

## Used By

- User invoked before creating PR

## Workflow

```
1. Get current branch name
2. Fetch latest from origin
3. Check for unstaged changes → commit as "wip"
4. Update main branch
   - checkout main
   - pull origin main
   - yarn lib:build
5. Return to feature branch and sync
   - checkout <branch>
   - pull origin main
   - yarn lib:build
6. Install dependencies and codegen
   - yarn
   - yarn gql:codegen
7. Format and lint
   - yarn format
   - yarn biome lint
   - yarn lint
8. Show final state
   - git status
   - git diff
```

## After Cleanup

If formatter made changes:
```bash
git add -A && git commit -m "chore: format and lint"
```

Branch ready for:
- [[pr-template]]
- [[pr-create]]

## Error Handling

- Merge conflicts: Stop, inform user to resolve manually
- Build failures: Report error, ask how to proceed
- Lint errors: Show errors, ask if should continue

## Related Commands

- [[pr-template]] - Next step
- [[pr-create]] - Next step
- [[quick-rebuild]] - Lighter rebuild

## Tags

#sf-ui-web #pr-workflow #preparation
