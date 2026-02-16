# commands

**Skill:** `global:commands`
**Type:** Global Command

## Purpose

Show available commands and tools for current context.

## Uses

- git (detect repo, branch, PR status)
- gh CLI (detect PR)

## Used By

- User invoked for discovery

## Workflow

```
1. Detect current repository
   - Get repo name
   - Get current branch
   - Check for unstaged changes
   - Check for existing PR

2. Show context-aware recommendations
   - Based on repo type
   - Based on current state (changes, PR status)

3. Show global commands (always available)

4. Show repo-specific commands
   - sf-ui-web commands
   - block-builder-api commands
   - sf-js-libraries commands
   - notes commands

5. Show dev CLI commands (if available)

6. Show scout CLI commands (if in git repo)
```

## Output Sections

- **Recommended Next Steps** - Context-aware suggestions
- **Global Commands** - Always available
- **Repo-Specific Commands** - Based on detected repo
- **dev CLI** - Context-aware development commands
- **scout CLI** - GitHub/CI automation

## Related Commands

- [[dev]] - Show dev CLI commands
- All other commands listed in output

## Tags

#global #discovery #help
