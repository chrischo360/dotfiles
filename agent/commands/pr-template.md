---
description: Generate PR title and description from git changes
---
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

6. Identify distinct changes and order them logically:
   - List all distinct changes by modified component/concern
   - Build a rough dependency graph: which changes enable or require other changes?
     * Schema/type changes → utilities/hooks → components → UI layer (foundational first)
     * Or narrative: inciting change → fix → downstream effects (story order)
   - Choose ordering heuristic:
     * **Foundational first** when changes are layered (new type → new hook → new component)
     * **Story order** when there's a clear narrative arc (problem → solution → guard)
     * Default to foundational first if neither is obvious
   - Single cohesive change: no bullets needed, incorporate into paragraph

7. Generate PR title and description:
   - **PR Title** (under 70 characters): `[PGL-XXX] <terse description>`
     * Focus on primary/largest change
     * Examples: "[PGL-947] Update HFC banner styling with responsive gem"
     * Examples: "[PGL-123] Add VPN documentation for build commands"

   - **PR Description** following these rules:
     * **Flowing paragraph** - One paragraph covering WHAT changed, WHY it was needed (technical and/or business when both are relevant and clarifying), and HOW the approach was chosen (key decisions, tradeoffs)
       - Include business why only when it clarifies the technical decision
       - Every clause earns its place: cut "this change", "in order to", "we decided to"
       - Paragraph explains intent; bullets enumerate the changes
     * **Bullet points** - Ordered by dependency graph or story flow (most foundational/inciting first)
       - Terse verb phrases, no file names, no filler
       - Include inline why when non-obvious and concise: "Add gem alignment enum (TOP/CENTER/BOTTOM) — SVG lacked positional API"
       - Drop the why when it's obvious from the what

8. Output the formatted PR title and body:

**Title:**
```
[PGL-XXX] <terse description>
```

**Body:**

```markdown
## Description
[PGL-XXX](https://projecthub.service.csnzoo.com/browse/PGL-XXX)

<One flowing paragraph: WHAT changed, WHY needed (technical + business when relevant), HOW approach was decided>

- <Most foundational/inciting change — inline why if non-obvious>
- <Change that depends on above>
- <Further downstream change>
- <Final/surface-level change>

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
- Bullets in diff/arbitrary order — order must reflect dependency chain or narrative arc
- Paragraph that lists changes instead of explaining them — paragraph = WHAT/WHY/HOW, bullets = the changes
- Inline why that restates the what ("Add X because we needed X")
