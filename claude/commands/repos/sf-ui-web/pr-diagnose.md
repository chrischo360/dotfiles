Watch PR checks and diagnose failures with proposed fixes.

Wrapper for `dev :run pr:diagnose` in sf-ui-web.

Steps:

1. Verify we're in sf-ui-web repository:
   ```bash
   git remote -v | grep -q 'sf-ui-web' || { echo "❌ Not in sf-ui-web repository"; exit 1; }
   ```

2. Run the pr:diagnose script:
   ```bash
   dev :run pr:diagnose
   ```

What this does:
- **Watch**: Uses `scout watch-builds` to monitor GitHub PR CI checks
- **On Failure**: Spawns AI agent to diagnose and propose fix
  - Reads failure logs
  - Analyzes the root cause
  - **Proposes fix** (does NOT apply changes)
  - Desktop notification when diagnosis complete
- **On Success**: Desktop notification that PR is ready

How diagnosis works:
1. Failure detected in CI checks
2. Spawns new Claude agent via `cli-agent`
3. Agent receives context: project, script, failed step, log path
4. Agent reads full log and analyzes failure
5. **Agent proposes changes** (does not commit)
6. Desktop notification: "Check Claude session for proposed fix"
7. **You review** the proposed fix
8. **You decide**: Apply fix + run `/pr-check` to test locally

Error handling:
- If not in sf-ui-web: Exits with error
- If no PR exists: Exits with error (must create PR first)
- Desktop notification on success/failure

Related commands:
- `/pr-submit` - Watch without diagnosis
- `/pr-automerge` - Watch + auto-merge on success
- `/pr-check` - Test proposed fix locally

Notes:
- Requires existing PR before running
- Create PR with: `gh pr create`
- Agent proposes fixes but does NOT auto-apply
- Review proposed changes before applying
- Run `/pr-check` locally to verify fix before pushing

Workflow example:
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

Anti-Patterns to Avoid:
- Don't run without a PR - create PR first
- Don't skip reviewing the proposed fix - verify before applying
- Don't apply fixes blindly - understand what changed
