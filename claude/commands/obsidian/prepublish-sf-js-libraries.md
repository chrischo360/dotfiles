# prepublish (sf-js-libraries)

**Skill:** `repos:sf-js-libraries:prepublish`
**Type:** sf-js-libraries Command

## Purpose

Automate testing pre-published libraries in consuming repos.

## Uses

- [[buildkite-watch]] ← **invokes to monitor build**
- git (branch operations)
- yarn (publish to Verdaccio)

## Used By

- User invoked when testing library changes

## Workflow

```
1. Create feature variant in consuming repo
   - Create branch matching current branch name
   - Update package.json to use Verdaccio

2. Publish to Verdaccio
   - Build libraries
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
- [[prepublish-block-builder-api]] - Similar workflow for schema

## Tags

#sf-js-libraries #prepublish #library-testing #cross-repo
