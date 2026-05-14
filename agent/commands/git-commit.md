---
description: Interactive commit helper with branch validation and ticket reference check
---
Commit changes with branch name validation (warns if no ticket reference).

Interactive commit helper that validates branch naming and creates commits.

Steps:

1. Check for uncommitted changes:
   ```bash
   if [[ -z $(git status --short) ]]; then
     echo "Nothing to commit, working tree clean"
     exit 0
   fi
   ```

2. Validate branch name for ticket reference:
   ```bash
   BRANCH=$(git branch --show-current)

   # Check for common patterns: PGL-XXX, ph-XXX, ticket/XXX
   if ! echo "$BRANCH" | grep -qE '(PGL-[0-9]+|ph-[0-9]+|ticket/[0-9]+)'; then
     echo "⚠️  Branch name doesn't contain a ticket reference"
     echo "   Current branch: $BRANCH"
     echo "   Expected pattern: PGL-123, ph-456, or ticket/789"
     echo ""

     # Use AskUserQuestion:
     # Question: "Continue without ticket reference?"
     # Options: Yes / No
     # If No: exit 0
   fi
   ```

3. Show changes to be committed:
   ```bash
   echo "Changes to commit:"
   git status --short | head -20

   TOTAL=$(git status --short | wc -l | tr -d ' ')
   if [[ "$TOTAL" -gt 20 ]]; then
     echo "... and $((TOTAL - 20)) more files"
   fi
   echo ""
   ```

4. Get commit message using AskUserQuestion:
   - Question: "Enter commit message:"
   - Default suggestion: "wip"
   - User can provide custom message

5. Create commit:
   ```bash
   git add -A && git commit -m "$MESSAGE"
   ```

6. Show result and next steps:
   ```bash
   echo "✅ Commit created:"
   git log -1 --oneline
   echo ""
   echo "Next steps:"
   echo "  /pr-lint      # Quick validation (format + lint)"
   echo "  /pr-check     # Full validation (typecheck + build + test)"
   echo "  /pr-create    # Create pull request"
   ```

What this does:
- Validates branch name for ticket references
- Non-blocking warning (user can continue)
- Shows files to be committed
- Prompts for commit message
- Suggests next steps

Branch patterns detected:
- PGL-123 (Wayfair ProjectHub)
- ph-456 (generic project hub)
- ticket/789 (generic ticket format)

Error handling:
- No changes: Exit with message
- Missing ticket: Warn, ask to continue
- Empty message: Use "wip" as default

Notes:
- Warning is non-blocking (user choice)
- Always stages all changes (git add -A)
- Works in any git repository

Related commands:
- `/commit` - Conventional commit message generator (simpler, no branch validation)
- `/pr-create` - Create pull request after committing
