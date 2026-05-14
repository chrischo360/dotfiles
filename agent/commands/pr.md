---
description: Interactive PR workflow menu with repository detection
---
Interactive PR workflow menu with repository detection.

Steps:

1. Detect repository:
   ```bash
   REPO_NAME=$(basename $(git rev-parse --show-toplevel 2>/dev/null) 2>/dev/null || echo "unknown")

   if [[ "$REPO_NAME" == "unknown" ]]; then
     echo "❌ Not in a git repository"
     exit 1
   fi
   ```

2. Build adaptive menu using AskUserQuestion:

   **Base options (all repos):**
   - Create PR - Full workflow: validation, template, push, create
   - Generate PR Description - Just title and body
   - Git Commit - Commit with branch validation
   - Quick Lint - Format and lint only
   - Watch PR - Monitor CI checks
   - PR Dashboard - View all PRs

   **sf-ui-web additional options:**
   - Build - Commit, sync main, rebuild, format
   - Check (Full) - Format, lint, typecheck, build, test
   - Push & Diagnose - Push + watch + auto-diagnose failures
   - Auto-merge - Watch + merge on success

   **Other repos with custom commands:**
   - Dynamically show any `repos/${REPO_NAME}/pr-*.md` commands found

3. Based on selection, invoke corresponding skill:
   - Create PR → `global:pr-create`
   - Generate PR Description → `global:pr-template`
   - Git Commit → `global:git-commit`
   - Quick Lint → `global:pr-lint`
   - Watch PR → `global:pr-watch`
   - PR Dashboard → `global:pr-dashboard`
   - Build → `repos:sf-ui-web:pr-build`
   - Check (Full) → `repos:sf-ui-web:pr-check`
   - Push & Diagnose → `repos:sf-ui-web:pr-push`
   - Auto-merge → `repos:sf-ui-web:pr-automerge`

What this does:
- Adapts to repository context
- Shows only available options
- Delegates to appropriate command

Notes:
- Works in any git repository
- sf-ui-web gets full workflow options
- Other repos get base PR tools
- Custom repo commands appear automatically
