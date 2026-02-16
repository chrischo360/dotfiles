# pr-automerge

**Skill:** `repos:sf-ui-web:pr-automerge`
**Type:** sf-ui-web Command

## Purpose

Watch PR checks, auto-merge when all checks pass.

## Uses

- dev CLI (`dev :run pr:automerge`) ← **wraps this script**
  - Uses scout watch-builds (same as [[pr-watch]])
  - gh CLI (for merge)

## Used By

- [[pr-create]] (suggested next step)
- User invoked for hands-off merging

## Workflow

```
1. Verify in sf-ui-web repository

2. Watch PR checks
   - Poll PR status every 30 seconds
   - Show real-time check results

3. On Success:
   - Run: gh pr merge --auto --squash
   - Desktop notification on merge

4. On Failure:
   - Stop and report failure
   - No auto-fix
```

## Error Handling

- If not in sf-ui-web: Exit with error
- If no PR exists: Exit with error
- If checks fail: Stop watching, report failure
- Desktop notification on success/failure

## Notes

- Requires existing PR before running
- Uses squash merge (single commit on main)
- PR must be approved before merge (GitHub setting)
- Press Ctrl+C to stop watching

## Related Commands

- [[pr-submit]] - Watch without auto-merge
- [[pr-diagnose]] - Watch + diagnose failures
- [[pr-check]] - Validation only
- [[pr-watch]] - Monitoring component

## Anti-Patterns

- Don't use for PRs requiring manual review - get approval first
- Don't interrupt watch - let it complete
- Don't use if you want rebase/merge commit - this uses squash

## Tags

#sf-ui-web #pr-workflow #monitoring #automation
