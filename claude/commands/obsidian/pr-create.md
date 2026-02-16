# pr-create

**Skill:** `global:pr-create`
**Type:** Global Command

## Purpose

Create GitHub PR with automated workflow (checks, template, push, create).

## Uses

- [[pr-template]] ← **invokes to generate title/body**
- [[pr-check]] ← **optionally invokes for validation** (if available)
- git (push, branch validation)
- gh CLI (create PR)

## Used By

- [[pr-cleanup]] (suggested next step)
- User invoked to create PR

## Workflow

```
1. Pre-flight validation
   - Check not on main/master
   - Check gh CLI authenticated
   - Check branch has commits
   - Warn about uncommitted changes

2. Optional: run pr-check (if available)

3. Invoke pr-template
   - Get title and body

4. Push branch to remote

5. Create PR with gh CLI

6. Display next steps
   - pr-watch
   - pr-automerge
   - pr-dashboard
```

## Flags

- `--skip-check` - Skip repo-specific pr-check execution
- `--skip-push` - Skip git push step
- `--dry-run` - Show what would happen without creating PR

## Next Steps

- [[pr-watch]] - Monitor CI checks
- [[pr-automerge]] - Auto-merge when checks pass
- [[pr-dashboard]] - View all PRs

## Related Commands

- [[pr-template]] - Used internally
- [[pr-check]] - Optional validation
- [[pr-cleanup]] - Preparation step

## Tags

#global #pr-workflow #orchestration
