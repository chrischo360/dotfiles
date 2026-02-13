Generate PR title and description from git changes matching your terse, technical style.

Steps:

1. Check current branch: `git branch --show-current`
2. Extract ticket ID from branch name: `git branch --show-current | grep -oE 'PGL-[0-9]+'`
   - If no PGL ticket found, use placeholder `PGL-XXX` in output

3. Determine what changes to analyze (in priority order):
   a. If user specifies a commit/range, use that
   b. Check for staged changes: `git diff --staged --stat`
   c. If no staged changes, check unstaged: `git diff --stat`
   d. If working tree clean AND on feature branch (not main/master):
      - Compare branch to main: `git diff main...HEAD --stat`
   e. If still no changes found, inform user and exit

4. Get full diff based on step 3:
   - Staged: `git diff --staged`
   - Unstaged: `git diff`
   - Branch: `git diff main...HEAD`

5. Identify distinct changes by analyzing:
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

6. Generate PR title and description:
   - **PR Title** (under 70 characters): `PGL-XXX: <terse description>`
     * Focus on primary/largest change
     * Examples: "PGL-947: Update HFC banner styling with responsive gem"
     * Examples: "PGL-123: Add VPN documentation for build commands"

   - **PR Description** following these rules:
     * **Terse and technical** - no marketing language
     * **What changed, not why** - focus on concrete changes
     * **Direct language** - "Add X", "Update Y", "Fix Z"
     * **No explanations** - code speaks for itself
     * Examples of good descriptions:
       - "Add HighFrictionCheckoutExperience as supported block in checkout"
       - "Add documentation for VPN requirements in build commands and GraphQL codegen"
       - "Update schema with detailed documentation and adjust field requirements for loyalty HFC checkout"

7. Output the formatted PR title and body:

**Title:**
```
PGL-XXX: <terse description>
```

**Body:**

```markdown
## Description
[PGL-XXX](https://projecthub.service.csnzoo.com/browse/PGL-XXX)

[Generated 1-2 sentence description based on git diff]

### How has this change been verified?

Tested using dev environment

- [ ] Verified in dev/core-funnel

## Screenshots (if appropriate):

## SOX Compliance

PH: PGL-XXX
BR: mro
TESTED: true
```

Replace `PGL-XXX` with the actual ticket ID if found in step 2.

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
