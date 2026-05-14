---
description: Watch a PR and auto-merge; diagnose and fix CI failures or merge conflicts
---
Watch a PR and auto-merge when ready. If blocked by CI failures or merge conflicts, diagnose and propose a fix plan.

Steps:

1. Run the watcher and capture exit code:
   ```bash
   pr-spam-merge $ARGUMENTS; echo "EXIT:$?"
   ```

2. If exit code is 0: done, PR merged successfully.

3. If exit code is 2 (BLOCKED — CI failure):
   - Determine PR number: use $ARGUMENTS if provided, otherwise `gh pr view --json number -q .number`
   - Fetch failing checks:
     ```bash
     gh pr checks $PR_NUMBER 2>&1
     ```
   - Find the Buildkite build URL from the output and fetch the failure logs
   - Read the relevant source files to understand the failure
   - Create a plan with the proposed code changes to fix the CI failure
   - Show the plan and ask the user for confirmation before making any changes

4. If exit code is 3 (DIRTY — merge conflict):
   - Determine PR number as above
   - Fetch conflicting files:
     ```bash
     git diff --name-only --diff-filter=U
     ```
   - Read the conflicting files and understand both sides of the conflict
   - Create a plan with the proposed merge resolution changes
   - Show the plan and ask the user for confirmation before making any changes

5. If exit code is 4 (DRAFT): inform the user the PR is still a draft and stop.
