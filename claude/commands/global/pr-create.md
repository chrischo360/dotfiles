Create GitHub PR with automated workflow (checks, template, push, create).

Automates PR creation: optional pre-checks, template generation, branch push, GitHub PR creation.

Steps:

1. Pre-flight validation (parallel execution):
   - Run these checks in parallel using multiple Bash tool calls in a single message:

   **Check 1: Branch validation**
   ```bash
   CURRENT_BRANCH=$(git branch --show-current)
   if [[ "$CURRENT_BRANCH" =~ ^(main|master)$ ]]; then
     echo "ERROR: Cannot create PR from main/master branch"
     exit 1
   fi
   echo "✓ Branch: $CURRENT_BRANCH"
   ```

   **Check 2: GitHub authentication**
   ```bash
   gh auth status 2>&1 | grep -q "Logged in" || {
     echo "ERROR: Not authenticated with GitHub. Run: gh auth login"
     exit 1
   }
   echo "✓ GitHub authenticated"
   ```

   **Check 3: Branch has commits**
   ```bash
   COMMIT_COUNT=$(git rev-list --count HEAD ^main 2>/dev/null)
   if [[ "$COMMIT_COUNT" -eq 0 ]]; then
     echo "ERROR: No commits on this branch"
     exit 1
   fi
   echo "✓ Branch has $COMMIT_COUNT commit(s)"
   ```

   **Check 4: Cache remote info (for Step 4)**
   ```bash
   # Store remote branch info to avoid redundant checks later
   REMOTE_BRANCH=$(git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null || echo "")
   if [[ -n "$REMOTE_BRANCH" ]]; then
     LOCAL_COMMIT=$(git rev-parse HEAD)
     REMOTE_COMMIT=$(git rev-parse @{u} 2>/dev/null || echo "")
     echo "REMOTE_INFO:has_tracking=true:local=$LOCAL_COMMIT:remote=$REMOTE_COMMIT"
   else
     echo "REMOTE_INFO:has_tracking=false"
   fi
   ```

   - If any check outputs "ERROR:", stop execution and show the error message
   - Parse and store the REMOTE_INFO output for use in Step 4

1.5. Handle uncommitted changes:
   ```bash
   # Check for uncommitted changes
   if [[ -n $(git status --short) ]]; then
     # Show what would be committed
     echo "⚠️  You have uncommitted changes:"
     git status --short | head -10
     echo ""

     # Use AskUserQuestion:
     # Question: "Commit these changes before creating PR?"
     # Options:
     #   - Yes - Commit all changes now
     #   - No - Continue without committing (PR won't include these changes)
     #   - Cancel - Exit without creating PR

     # If Yes:
     #   - Use AskUserQuestion again:
     #     - Question: "Enter commit message (or leave blank for 'wip'):"
     #     - Default: "wip"
     #   - git add -A && git commit -m "<message>"

     # If No:
     #   - echo "⚠️  Continuing without uncommitted changes. PR will not include them."

     # If Cancel:
     #   - echo "❌ PR creation cancelled"
     #   - exit 0
   fi
   ```

2. Optional: Run adaptive validation (configurable):
   - **Default behavior: Skip validation** (faster PR creation)
   - If `--with-check` flag provided: Run validation
   - If `--skip-check` flag: Explicitly skip (for backward compatibility)

   **When validation runs:**
   - Get repository name: `basename $(git rev-parse --show-toplevel)`
   - Try repo-specific pr-check: `repos:<repo-name>:pr-check`
   - If not found, try global pr-lint: `global:pr-lint`
   - If validation fails: Ask "Validation failed. Continue with PR creation?"

   **Validation details:**
   For sf-ui-web, `repos:sf-ui-web:pr-check` runs:
   - `dev :run pr:check` which executes:
     - yarn format
     - yarn lint
     - yarn type-check
     - yarn lib:build
     - yarn test

   **Recommended workflow:**
   - Use `/pr-build` before `/pr-create` (handles formatting, linting, syncing)
   - Skip pr-check during PR creation for speed
   - CI will catch issues automatically

3. Generate PR template and pre-fetch remote (parallel execution):
   - Run these operations in parallel using multiple tool calls in a single message:

   **Operation 1: Generate PR template**
   - Invoke `/pr-template` skill
   - Parse output format:
     ```
     **Title:**
     ```
     [PGL-XXX] Description
     ```

     **Body:**
     ```markdown
     ...
     ```
     ```
   - Extract title from code block after `**Title:**`
   - Extract body from code block after `**Body:**`
   - Store in `$PR_TITLE` and `$PR_BODY` variables

   **Operation 2: Pre-fetch remote state (background)**
   ```bash
   git fetch origin 2>&1 | grep -q "error" && echo "FETCH_FAILED" || echo "FETCH_OK"
   ```

   **If pr-check is running (--with-check flag):**
   - Wait for pr-check to complete
   - Check result and ask to continue if it failed

   **Note:** pr-template analyzes git diff and may use MCP servers (Glean/Confluence/Jira) if available to fetch ticket context.

4. Push branch to remote (optimized - reuses cached data):
   - If `--skip-push` flag: Skip this step

   **Use cached REMOTE_INFO from Step 1:**
   ```bash
   # Parse cached remote info from Step 1 (no redundant git commands)
   # REMOTE_INFO format: "has_tracking=true:local=<sha>:remote=<sha>"

   if [[ "$HAS_TRACKING" == "false" ]]; then
     # No remote tracking - push with -u
     echo "Pushing branch to origin..."
     git push -u origin HEAD || {
       echo "❌ Failed to push branch"
       exit 1
     }
   else
     # Check if local is ahead of cached remote
     # Note: Step 3 already ran git fetch, so remote refs are fresh
     CURRENT_LOCAL=$(git rev-parse HEAD)
     CURRENT_REMOTE=$(git rev-parse @{u} 2>/dev/null)

     if [[ "$CURRENT_LOCAL" != "$CURRENT_REMOTE" ]]; then
       # Check if diverged
       git merge-base --is-ancestor "$CURRENT_REMOTE" "$CURRENT_LOCAL" 2>/dev/null
       if [[ $? -ne 0 ]]; then
         echo "❌ Branch has diverged from remote."
         echo "   Run: git pull --rebase or git push --force-with-lease"
         exit 1
       fi

       # Local ahead - push updates
       echo "Pushing new commits to origin..."
       git push || {
         echo "❌ Failed to push branch"
         exit 1
       }
     else
       echo "✓ Branch already up to date on origin"
     fi
   fi
   ```

5. Create PR with gh CLI:
   ```bash
   # Use title and body from pr-template (step 3)
   PR_URL=$(gh pr create --title "$PR_TITLE" --body "$PR_BODY" 2>&1)

   # Check if creation succeeded
   if [[ $? -ne 0 ]]; then
     # Check if error is "PR already exists"
     if gh pr view &>/dev/null; then
       echo ""
       echo "✅ PR already exists for this branch:"
       gh pr view
       echo ""
       echo "Next steps:"
       echo "  gh pr view --web    # View in browser"
       echo "  /pr-push            # Push changes and diagnose"
       echo ""
       exit 0
     else
       echo "❌ Failed to create PR"
       echo "$PR_URL"
       exit 1
     fi
   fi

   echo ""
   echo "✅ PR created successfully!"
   echo "   $PR_URL"
   echo ""
   ```

6. Display next steps and exit:
   ```bash
   echo "Next steps (copy and run as needed):"
   echo ""
   echo "  # Review PR in browser"
   echo "  gh pr view --web"
   echo ""
   echo "  # Watch CI checks in real-time"
   echo "  /pr-watch"
   echo ""
   echo "  # View PR dashboard for this repo"
   echo "  /pr-dashboard"
   echo ""
   echo "  # Auto-merge when checks pass (requires approval)"
   echo "  /pr-automerge"
   echo ""
   ```

What this does:
- **Pre-flight**: Validates prerequisites (not on main, gh auth, has commits)
- **pr-check**: Runs repo-specific validation if available
- **pr-template**: Generates title and description from git changes
- **Push**: Ensures branch is on remote
- **Create**: Creates GitHub PR with generated content
- **Exit**: Shows suggested next steps, user decides

Flags:
- `--with-check` - Run pr-check validation (slower, ~5-15s additional time)
- `--skip-check` - Explicitly skip validation (default behavior, kept for backward compatibility)
- `--skip-push` - Skip git push step (branch already pushed)
- `--dry-run` - Show what would happen without creating PR

Default: Validation is skipped unless `--with-check` is provided

Examples:
```bash
# Fast mode (default - no validation, ~7-10s)
/pr-create

# With validation (~14-25s)
/pr-create --with-check

# Skip validation explicitly (backward compat)
/pr-create --skip-check

# Skip push (branch already pushed)
/pr-create --skip-push

# Dry run
/pr-create --dry-run

# Combine flags
/pr-create --with-check --skip-push
```

Recommended workflow:
```bash
# Before PR creation: build, format, lint, sync with main
/pr-build

# Create PR quickly (validation already done)
/pr-create

# Watch CI status after creation
/pr-watch
```

Error handling:
- On main/master: Exit with error
- gh not authenticated: Exit with clear instructions
- No commits: Exit with error
- pr-check fails: Ask user to continue or exit
- Branch diverged: Exit with resolution commands
- PR already exists: Exit with view instructions
- Push fails: Exit with error

Related commands:
- `/pr-template` - Generate PR description (used internally)
- `/pr-check` - Run validation suite (called conditionally)
- `/pr-watch` - Monitor PR CI checks (suggested next step)
- `/pr-build` - Prepare branch before PR (run before this command)
- `/pr-automerge` - Auto-merge when checks pass
- `/pr-dashboard` - View all PRs for repository

Notes:
- Works across all repositories
- Intelligently adapts to repo-specific features (pr-check)
- Non-interactive after pr-check failure prompt
- User controls next steps via suggested commands
- Requires gh CLI authentication
- Assumes git remote "origin" exists

Anti-Patterns to Avoid:
- Don't use on main/master - create feature branch first
- Don't retry on "PR exists" error - use `gh pr view` instead
- Don't commit changes during PR creation - commit first
