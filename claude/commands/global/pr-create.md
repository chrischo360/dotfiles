Create GitHub PR with automated workflow (checks, template, push, create).

Automates PR creation: optional pre-checks, template generation, branch push, GitHub PR creation.

**Optimization goals:** Minimize round-trips. Consolidate checks. Don't ask unnecessary questions.

Steps:

1. Pre-flight validation (SINGLE bash call):
   - Run ALL checks in ONE compound bash command, not parallel separate calls:

   ```bash
   # All preflight in one command
   CURRENT_BRANCH=$(git branch --show-current)
   [[ "$CURRENT_BRANCH" =~ ^(main|master)$ ]] && { echo "ERROR: Cannot create PR from main/master branch"; exit 1; }
   echo "Branch: $CURRENT_BRANCH"

   gh auth status &>/dev/null || { echo "ERROR: Not authenticated with GitHub. Run: gh auth login"; exit 1; }
   echo "GitHub: authenticated"

   COMMIT_COUNT=$(git rev-list --count HEAD ^main 2>/dev/null)
   [[ "$COMMIT_COUNT" -eq 0 ]] && { echo "ERROR: No commits on this branch"; exit 1; }
   echo "Commits: $COMMIT_COUNT"

   # Cache remote tracking info for push step
   REMOTE_BRANCH=$(git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null || echo "")
   if [[ -n "$REMOTE_BRANCH" ]]; then
     echo "REMOTE_INFO:has_tracking=true:local=$(git rev-parse HEAD):remote=$(git rev-parse @{u} 2>/dev/null)"
   else
     echo "REMOTE_INFO:has_tracking=false"
   fi

   # Check for uncommitted changes
   UNCOMMITTED=$(git status --short)
   if [[ -n "$UNCOMMITTED" ]]; then
     echo "UNCOMMITTED_CHANGES:true"
     echo "$UNCOMMITTED" | head -10
   else
     echo "UNCOMMITTED_CHANGES:false"
   fi
   ```

   - If output contains "ERROR:", stop and show the error
   - Parse REMOTE_INFO for use in push step
   - If UNCOMMITTED_CHANGES:true, use AskUserQuestion:
     - Question: "Commit these changes before creating PR?"
     - Options: Yes (commit all), No (continue without), Cancel (exit)
     - If Yes: ask for commit message (default "wip"), then `git add -A && git commit -m "<message>"`

2. Optional: Run adaptive validation (configurable):
   - **Default behavior: Skip validation** (faster PR creation)
   - If `--with-check` flag provided: Run validation
   - If `--skip-check` flag: Explicitly skip (for backward compatibility)

   **When validation runs:**
   - Get repository name: `basename $(git rev-parse --show-toplevel)`
   - Try repo-specific pr-check: `repos:<repo-name>:pr-check`
   - If not found, try global pr-lint: `global:pr-lint`
   - If validation fails: Ask "Validation failed. Continue with PR creation?"

3. Push branch + create draft PR immediately (parallel, 2 calls):
   - Run these two operations in parallel using multiple tool calls in a single message:

   **Operation 1: Fetch remote + push in one command**
   ```bash
   git fetch origin 2>/dev/null

   REMOTE_BRANCH=$(git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null || echo "")
   if [[ -z "$REMOTE_BRANCH" ]]; then
     git push -u origin HEAD || { echo "PUSH_FAILED"; exit 1; }
   else
     CURRENT_LOCAL=$(git rev-parse HEAD)
     CURRENT_REMOTE=$(git rev-parse @{u} 2>/dev/null)
     if [[ "$CURRENT_LOCAL" != "$CURRENT_REMOTE" ]]; then
       git merge-base --is-ancestor "$CURRENT_REMOTE" "$CURRENT_LOCAL" 2>/dev/null || {
         echo "DIVERGED: Branch has diverged from remote. Run: git pull --rebase or git push --force-with-lease"
         exit 1
       }
       git push || { echo "PUSH_FAILED"; exit 1; }
     else
       echo "Branch already up to date on origin"
     fi
   fi
   ```

   - If `--skip-push` flag: replace Operation 1 with just `git fetch origin 2>/dev/null`
   - If push fails or diverged: stop and show error

   **Operation 2: Generate PR template**
   - Invoke `global:pr-template` skill (MUST use fully qualified name)
   - **Do NOT display the template output to the user** — capture `$PR_TITLE` and `$PR_BODY` silently for use in the next step
   - The template skill will print a title block and body block — parse them from the skill's return value

4. Create PR with gh CLI using the captured template:
   - Wait for both Operation 1 (push) and Operation 2 (template) to complete
   - Use the `$PR_TITLE` and `$PR_BODY` parsed from the template output
   - **Do not show the template to the user before creating the PR**

   ```bash
   PR_URL=$(gh pr create --title "$PR_TITLE" --body "$PR_BODY" 2>&1)

   if [[ $? -ne 0 ]]; then
     if gh pr view &>/dev/null; then
       echo "PR already exists for this branch:"
       gh pr view --json url -q '.url'
       exit 0
     else
       echo "Failed to create PR: $PR_URL"
       exit 1
     fi
   fi

   echo "$PR_URL"
   ```

5. Run lint after PR creation and commit fixes if needed:
   - Invoke `global:pr-lint` skill
   - After lint completes, check for modified files:
     ```bash
     LINT_CHANGES=$(git status --short)
     echo "$LINT_CHANGES"
     ```
   - If LINT_CHANGES is non-empty (lint auto-fixed files):
     - Use AskUserQuestion: "Lint fixed some issues. Commit and push them?"
     - Options: Yes, No
     - If Yes:
       ```bash
       git add -A && git commit -m "fix: lint"
       git push
       ```
   - If lint reports unfixable errors: show output, continue to next steps
   - If lint passes cleanly: continue silently

6. Display next steps and exit:
   - Show PR URL
   - Suggest: `gh pr view --web`, `/pr-watch`, `/pr-dashboard`, `/pr-automerge`

**Ticket ID handling:**
- Extract from branch name: `git branch --show-current | grep -oE '[A-Z]+-[0-9]+'`
- Matches PGL-XXX, APR-XXX, or any JIRA-style ticket
- If no ticket found: proceed silently without asking the user
- pr-template will handle including/omitting the ticket ID in the output

**Round-trip budget (target: 4 tool calls for happy path):**
1. Single bash: all preflight checks + uncommitted status + remote info
2. Parallel: fetch/push bash + `global:pr-template` skill (both in same message)
3. Single bash: `gh pr create` (using template output captured from step 2)
4. Skill: `global:pr-lint` (post-PR)
5. If lint auto-fixed files: 1 AskUserQuestion + 1 bash (commit + push)

If uncommitted changes exist, add 1 AskUserQuestion call (+ 1 bash for commit if yes).

Flags:
- `--with-check` - Run pr-check validation before PR creation
- `--skip-check` - Explicitly skip validation (default behavior)
- `--skip-push` - Skip git push step (branch already pushed)
- `--dry-run` - Show what would happen without creating PR

Default: Validation is skipped unless `--with-check` is provided

Examples:
```bash
/pr-create
/pr-create --with-check
/pr-create --skip-push
/pr-create --dry-run
```

Error handling:
- On main/master: Exit with error
- gh not authenticated: Exit with clear instructions
- No commits: Exit with error
- pr-check fails: Ask user to continue or exit
- Branch diverged: Exit with resolution commands
- PR already exists: Show existing PR URL
- Push fails: Exit with error

Related commands:
- `global:pr-template` - Generate PR description (used internally, always use fully qualified name)
- `/pr-check` - Run validation suite (called conditionally)
- `/pr-watch` - Monitor PR CI checks (suggested next step)
- `/pr-build` - Prepare branch before PR (run before this command)
- `/pr-automerge` - Auto-merge when checks pass

Anti-Patterns to Avoid:
- Don't use on main/master - create feature branch first
- Don't retry on "PR exists" error - use `gh pr view` instead
- Don't ask the user about missing ticket IDs - just proceed
- Don't use `gh auth status | grep` - use exit code instead
- Don't split preflight into multiple parallel bash calls - one compound command is faster
- Don't invoke `/pr-template` - use `global:pr-template` (fully qualified name)
- **Don't display the pr-template output to the user** — parse title/body from it silently and proceed directly to `gh pr create`. The template is an internal intermediate artifact, not a user response. Surfacing it and stopping is a bug.
- **Don't stop after generating the template** — always continue to `gh pr create` in the same flow
