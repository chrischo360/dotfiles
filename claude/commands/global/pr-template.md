Generate PR title and description from git changes matching your terse, technical style.

Steps:

1. Check current branch: `git branch --show-current`
2. Extract ticket ID from branch name: `git branch --show-current | grep -oE 'PGL-[0-9]+'`
   - If no PGL ticket found, use placeholder `PGL-XXX` in output

3. **Fetch ticket context (if MCP tools available)**:
   a. Check if Glean MCP is available and use it to search for the ticket:
      - Search query: "PGL-XXX" or ticket title if known
      - Extract: ticket description, acceptance criteria, key requirements

   b. Check if Confluence MCP is available and search for related documentation:
      - Search for ticket ID or related feature/component names
      - Look for: technical specs, design docs, implementation notes

   c. If Jira/ProjectHub direct access available:
      - Fetch ticket summary, description, acceptance criteria
      - Note any linked tickets or dependencies

   **Use this context to**:
   - Better understand the intent behind code changes
   - Include relevant context in PR description if it clarifies the change
   - Ensure PR description aligns with ticket requirements
   - Skip if MCPs unavailable - proceed with git diff analysis only

4. Determine what changes to analyze (in priority order):
   a. If user specifies a commit/range, use that
   b. Check for staged changes: `git diff --staged --stat`
   c. If no staged changes, check unstaged: `git diff --stat`
   d. If working tree clean AND on feature branch (not main/master):
      - Compare branch to main: `git diff main...HEAD --stat`
   e. If still no changes found, inform user and exit

5. Get full diff based on step 4:
   - Staged: `git diff --staged`
   - Unstaged: `git diff`
   - Branch: `git diff main...HEAD`

6. Identify distinct changes by analyzing:
   - Modified directories/components (e.g., libs/financing-lab, libs/support-center, apps/core-funnel)
   - Change types: new features, bug fixes, styling updates, refactors, schema changes
   - File groupings that indicate separate concerns

   Decision logic:
   - **Single cohesive change** (all files relate to one feature/fix): Use single sentence
   - **2 related changes**: Combine into one sentence if possible, otherwise 2 bullets
   - **3+ unrelated changes** across different domains: Use bullet points

   Examples:
   - Single: "Update HFC banner styling with responsive gem positioning and LoadingButton states"
   - Multiple distinct:
     * Add HFC gem positioning with alignment controls in financing-lab
     * Implement HTML sanitization for support center comments
     * Update GraphQL schema with loyalty enrollment fields

7. Generate PR title and description:
   - **PR Title** (under 70 characters): `[PGL-XXX] <terse description>`
     * Focus on primary/largest change
     * Examples: "[PGL-947] Update HFC banner styling with responsive gem"
     * Examples: "[PGL-123] Add VPN documentation for build commands"

   - **PR Description** following these rules:
     * **Brief summary** - 1-2 sentence overview of what changed
       - If ticket context available from step 3, incorporate relevant intent/requirements
       - Keep focused on technical implementation, not business justification
     * **Bullet points** - List key technical changes without file names
     * **Concise language** - "Refactor X", "Add Y", "Update Z"
     * **No detailed explanations** - AI bot adds technical analysis automatically
     * Examples matching Wayfair contributor style:
       - Summary: "Update HighFrictionCheckoutBanner with responsive gem positioning, LoadingButton states, and improved button/radio spacing."
       - Bullets:
         * Refactor Gem component to use BlockBuilder FixedImage instead of hardcoded SVG
         * Add configurable gem alignment (TOP/CENTER/BOTTOM) with responsive display (desktop only)
         * Replace Button with LoadingButton for enrollment/decline actions
         * Update button variations: condensed mobile buttons, primary/secondary desktop hierarchy
         * Adjust radio button spacing and sizing for better alignment

8. Output the formatted PR title and body:

**Title:**
```
[PGL-XXX] <terse description>
```

**Body:**

```markdown
## Description
[PGL-XXX](https://projecthub.service.csnzoo.com/browse/PGL-XXX)

<Brief 1-2 sentence summary>

- <Bullet point of key change without file references>
- <Another key change>
- <Additional changes as needed>

### How has this change been verified?

Tested using dev environment

- [ ] Verified in dev/core-funnel

## Screenshots (if appropriate):

## SOX Compliance

PH: PGL-XXX
BR: ghallinan
TESTED: true
```

Replace `PGL-XXX` with the actual ticket ID if found in step 2.

**Ticket Context Integration:**
When ticket information is available from step 3:
- Use ticket summary to validate PR title accuracy
- Incorporate acceptance criteria into "How has this change been verified?" if relevant
- Reference specific requirements from ticket if they clarify technical decisions
- Don't copy/paste ticket description verbatim - synthesize with code changes
- Prefer code analysis over ticket context when they conflict

Analysis Focus:
- Modified file paths (identify component/feature)
- Added/removed functions or components
- Configuration changes
- Documentation updates
- Schema/type changes

Anti-Patterns to Avoid:
- Long explanations of why changes were made
- Marketing language ("exciting new feature")
- Implementation details ("uses useEffect to...")
- Future plans ("this will enable us to...")
