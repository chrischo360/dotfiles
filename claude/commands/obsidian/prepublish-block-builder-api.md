# prepublish (block-builder-api)

**Skill:** `repos:block-builder-api:prepublish`
**Type:** block-builder-api Command

## Purpose

Automate testing block-builder-api GraphQL schema changes in sf-ui-web.

## Uses

- [[buildkite-watch]] ← **invokes to monitor build**
- git (branch operations)
- yarn (publish to Verdaccio)

## Used By

- User invoked when testing schema changes

## Workflow

```
1. Create feature variant in sf-ui-web
   - Create branch matching current branch name
   - Update package.json to use Verdaccio

2. Publish to Verdaccio
   - Build schema
   - Publish to local registry

3. Invoke buildkite-watch
   - Monitor build progress
   - Wait for completion

4. Handle buildkite-watch exit codes
   - 0 (success): Continue to testing
   - 1 (failure): Ask to continue or exit
   - 2 (timeout): Ask to wait/skip/exit
   - 3 (no build): Warn and ask to continue

5. Test in dev environment
   - Instructions for manual testing
```

## Related Commands

- [[buildkite-watch]] - Build monitoring component
- [[prepublish-sf-js-libraries]] - Similar workflow for libraries

## Tags

#block-builder-api #prepublish #schema-testing #cross-repo
