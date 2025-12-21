Generate PR description from git changes matching your terse, technical style.

Steps:

1. Check for staged changes by running `git diff --staged --stat`
2. If no staged changes found, check unstaged changes with `git diff --stat`
3. If no changes at all, inform user and exit
4. Extract ticket ID from branch name: `git branch --show-current | grep -oE 'PGL-[0-9]+'`
   - If no PGL ticket found, use placeholder `PGL-XXX` in output
5. Get full diff for analysis: `git diff --staged` (or `git diff` if nothing staged)
6. Analyze the git diff and generate a 1-2 sentence description following these rules:
   - **Terse and technical** - no marketing language
   - **What changed, not why** - focus on concrete changes
   - **Direct language** - "Add X", "Update Y", "Fix Z"
   - **Use bullet points** only if 3+ distinct changes
   - **No explanations** - code speaks for itself
   - Examples of good descriptions:
     * "Add HighFrictionCheckoutExperience as supported block in checkout"
     * "Add documentation for VPN requirements in build commands and GraphQL codegen"
     * "Update schema with detailed documentation and adjust field requirements for loyalty HFC checkout"
7. Output the formatted PR body:

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

Replace `PGL-XXX` with the actual ticket ID if found in step 4.

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
