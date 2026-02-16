# pr-diagnose

**Skill:** `repos:sf-ui-web:pr-diagnose`
**Type:** sf-ui-web Command

## Purpose

Watch PR checks and diagnose failures with proposed fixes.

## Uses

- dev CLI (`dev :run pr:diagnose`) ← **wraps this script**
  - Uses scout watch-builds (same as [[pr-watch]])
  - Spawns Claude agent on failure

## Used By

- User invoked for automated diagnosis

## Workflow

```
1. Verify in sf-ui-web repository

2. Watch PR checks
   - Monitor CI status
   - Wait for completion

3. On Failure:
   - Spawn Claude agent via cli-agent
   - Agent receives: project, script, failed step, log path
   - Agent reads full log and analyzes failure
   - Agent proposes changes (does NOT commit)
   - Desktop notification: "Check Claude session for proposed fix"

4. User Reviews:
   - Review proposed fix
   - Apply fix if acceptable
   - Run pr-check to test locally
   - Push and watch again
```

## Error Handling

- If not in sf-ui-web: Exit with error
- If no PR exists: Exit with error (must create PR first)
- Desktop notification on success/failure

## Important

- Agent **proposes** fixes but does NOT auto-apply
- Review proposed changes before applying
- Run [[pr-check]] locally to verify fix before pushing

## Example Workflow

```bash
# 1. Create PR
gh pr create

# 2. Watch and diagnose failures
/pr-diagnose

# 3. Review proposed fix in Claude session
# 4. Apply fix if acceptable
# 5. Test locally
/pr-check

# 6. Push and watch again
git push && /pr-watch
```

## Related Commands

- [[pr-submit]] - Watch without diagnosis
- [[pr-automerge]] - Watch + auto-merge
- [[pr-check]] - Test proposed fix locally
- [[pr-watch]] - Monitoring component

## Tags

#sf-ui-web #pr-workflow #monitoring #ai-diagnosis
