# cherry-pick-merge

**Skill:** `global:cherry-pick-merge`
**Type:** Global Command

## Purpose

Cherry-pick commits from multiple branches into a new branch with automatic conflict resolution.

## Uses

- git (cherry-pick, merge, conflict resolution)

## Used By

- User invoked for complex git workflows

## Workflow

```
1. Prompt for:
   - Target branch name
   - Source branches/commits
   - Base branch (default: main)

2. Create new branch from base

3. Cherry-pick commits from each source
   - Handle conflicts automatically when possible
   - Prompt user for manual resolution when needed

4. Show summary of cherry-picked commits

5. Ask to push or continue locally
```

## Related Commands

None (standalone git utility)

## Tags

#global #git #workflow #cherry-pick
