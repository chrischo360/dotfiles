# pr-template

**Skill:** `global:pr-template`
**Type:** Global Command

## Purpose

Generate PR title and description from git changes matching your terse, technical style.

## Uses

- git (diff, branch info)
- Optional: Glean MCP (ticket context)
- Optional: Confluence MCP (documentation)
- Optional: Jira MCP (ticket details)

## Used By

- [[pr-create]] ← invokes to generate title/body
- [[pr-cleanup]] (suggested next step)
- User invoked manually

## Workflow

1. Extract ticket ID from branch name
2. Fetch ticket context (if MCP tools available)
3. Determine what changes to analyze (staged, unstaged, or branch)
4. Get full diff
5. Identify distinct changes
6. Generate PR title and description
7. Output formatted result

## Related Commands

- [[pr-create]] - Uses this to generate PR content
- [[pr-cleanup]] - Suggests using this afterward

## Tags

#global #pr-workflow #template-generation
