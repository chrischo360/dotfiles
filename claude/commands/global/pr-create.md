Create GitHub PR with automated workflow (checks, template, push, create).

Automates PR creation: optional pre-checks, template generation, branch push, GitHub PR creation.

Steps:

1. Pre-flight validation:
   ```bash
   # Check not on main/master branch
   CURRENT_BRANCH=$(git branch --show-current)
   if [[ "$CURRENT_BRANCH" =~ ^(main|master)$ ]]; then
     echo "❌ Cannot create PR from main/master branch"
     exit 1
   fi

   # Check gh CLI authenticated
   gh auth status 2>&1 | grep -q "Logged in" || {
     echo "❌ Not authenticated with GitHub. Run: gh auth login"
     exit 1
   }

   # Check branch has commits
   git rev-list --count HEAD ^main 2>/dev/null | grep -q '^0$' && {
     echo "❌ No commits on this branch"
     exit 1
   }
   ```

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

2. Optional: Run adaptive validation:
   - Get repository name: `basename $(git rev-parse --show-toplevel)`
   - Try repo-specific pr-check: `repos:<repo-name>:pr-check`
   - If not found, try global pr-lint: `global:pr-lint` (quick format + lint)
   - If validation fails: Ask "Validation failed. Continue with PR creation? (y/n)"
   - If `--skip-check` flag: Skip this step

3. Generate PR title and body via pr-template:
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

4. Push branch to remote:
   ```bash
   # Check if branch has remote tracking
   REMOTE_BRANCH=$(git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null)

   if [[ -z "$REMOTE_BRANCH" ]]; then
     # No remote tracking - push with -u
     echo "Pushing branch to origin..."
     git push -u origin HEAD || {
       echo "❌ Failed to push branch"
       exit 1
     }
   else
     # Remote tracking exists - check if up to date
     LOCAL_COMMIT=$(git rev-parse HEAD)
     REMOTE_COMMIT=$(git rev-parse @{u})

     if [[ "$LOCAL_COMMIT" != "$REMOTE_COMMIT" ]]; then
       # Check if diverged
       git merge-base --is-ancestor "$REMOTE_COMMIT" "$LOCAL_COMMIT" 2>/dev/null
       if [[ $? -ne 0 ]]; then
         echo "❌ Branch has diverged from remote."
         echo "   Run: git pull --rebase or git push --force-with-lease"
         exit 1
       fi

       # Local ahead of remote - push updates
       echo "Pushing new commits to origin..."
       git push || {
         echo "❌ Failed to push branch"
         exit 1
       }
     else
       echo "Branch already up to date on origin"
     fi
   fi
   ```
   - If `--skip-push` flag: Skip this step

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
- `--skip-check` - Skip repo-specific pr-check execution
- `--skip-push` - Skip git push step (branch already pushed)
- `--dry-run` - Show what would happen without creating PR

Examples:
```bash
# Basic usage (all steps)
/pr-create

# Skip pre-checks
/pr-create --skip-check

# Skip push (branch already pushed)
/pr-create --skip-push

# Dry run (see what would happen)
/pr-create --dry-run

# Combine flags
/pr-create --skip-check --skip-push
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
