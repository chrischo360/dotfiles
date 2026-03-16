Generate a comprehensive summary for a PGL ticket including branches, PRs, and ProjectHub link.

Given a ticket ID (e.g., PGL-627), this command:
- Finds all git branches containing the ticket ID across ~/codebase repositories
- Links to GitHub PRs if they exist
- Provides ProjectHub ticket link
- Groups all related information in one view

Steps:

1. Validate ticket format:
   ```bash
   TICKET="$1"
   [[ -z "$TICKET" ]] && echo "Usage: ticket-summary PGL-XXX" && exit 1
   [[ ! "$TICKET" =~ ^PGL-[0-9]+$ ]] && echo "❌ Invalid format. Use: PGL-XXX" && exit 1
   ```

2. Find all branches containing ticket ID across ~/codebase:
   ```bash
   echo "## Ticket: $TICKET"
   echo "ProjectHub: https://projecthub.service.csnzoo.com/browse/$TICKET"
   echo ""
   echo "### Branches and PRs:"
   echo ""

   # Search all repos in ~/codebase
   for repo in ~/codebase/*; do
     [ ! -d "$repo/.git" ] && continue

     cd "$repo"
     REPO_NAME=$(basename "$repo")

     # Find branches with ticket ID (case insensitive)
     BRANCHES=$(git branch -a | grep -i "$TICKET" | sed 's/^[* ]*//' | sed 's/remotes\/origin\///' | sort -u)

     if [ -n "$BRANCHES" ]; then
       echo "**$REPO_NAME:**"

       while IFS= read -r branch; do
         # Try to get PR URL for this branch
         PR_URL=$(git ls-remote --heads origin "$branch" &>/dev/null && gh pr list --head "$branch" --json url --jq '.[0].url' 2>/dev/null || echo "")

         if [ -n "$PR_URL" ]; then
           echo "  - \`$branch\` → $PR_URL"
         else
           echo "  - \`$branch\` (no PR)"
         fi
       done <<< "$BRANCHES"

       echo ""
     fi
   done
   ```

3. Check for work notes in ~/notes/work/:
   ```bash
   echo "### Work Notes:"
   echo ""

   NOTES=$(find ~/notes/work -type f -name "*${TICKET}*" 2>/dev/null)

   if [ -n "$NOTES" ]; then
     while IFS= read -r note; do
       echo "  - $(basename "$note")"
     done <<< "$NOTES"
   else
     echo "  - No work notes found"
   fi
   echo ""
   ```

What this does:
- **Step 1**: Validates ticket format (PGL-XXX)
- **Step 2**: Searches all git repos in ~/codebase for branches containing ticket ID
- **Step 3**: For each branch, attempts to find associated GitHub PR
- **Step 4**: Lists any work notes in ~/notes/work matching the ticket

Usage:
```bash
# In Claude Code
/ticket-summary PGL-627

# Output format:
## Ticket: PGL-627
ProjectHub: https://projecthub.service.csnzoo.com/browse/PGL-627

### Branches and PRs:
**sf-ui-web:**
  - `PGL-627-fix-login` → https://github.com/org/sf-ui-web/pull/123
  - `PGL-627-tests` (no PR)

### Work Notes:
  - PGL-627_login_fix.md
```

Options:
- Provide ticket ID as argument: `/ticket-summary PGL-627`
- If no argument provided, command will prompt for usage

Error handling:
- Missing ticket ID: Show usage message
- Invalid format: Warn and exit
- No branches found: Display message indicating no matches
- Git command failures: Skip repo and continue

Related commands:
- `/archive-week` - Archive weekly plans
- `/backlog-cleanup` - Clean up backlog

Notes:
- Searches case-insensitively for ticket ID in branch names
- Checks both local and remote branches
- Only scans repositories in ~/codebase with .git directory
- PR detection uses `gh` CLI - requires GitHub CLI to be installed and authenticated

Anti-Patterns to Avoid:
- Don't manually search repos one by one - this command searches all ~/codebase repos
- Don't forget ticket format (PGL-XXX not pgl-xxx)
- Don't assume PR exists - command shows "(no PR)" when not found
