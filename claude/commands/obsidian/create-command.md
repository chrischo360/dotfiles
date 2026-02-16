# create-command

**Skill:** `global:create-command`
**Type:** Global Command (Meta)

## Purpose

Generate a new Claude command from a natural language description.

## Uses

- File I/O (creates .md files)
- Template generation

## Used By

- User invoked to create new commands

## Workflow

```
1. Prompt for command details:
   - Command description
   - Scope (global or repo-specific)
   - Repository name (if repo-specific)
   - Command name
   - Parameters/flags (optional)

2. Generate structured content:
   - Purpose
   - Steps
   - What this does
   - Error handling
   - Related commands
   - Examples
   - Notes
   - Anti-patterns

3. Create file in correct location:
   - global/ or repos/<repo-name>/

4. Validate format

5. Register as skill (automatic on next session)
```

## Related Commands

All commands (this creates them)

## Tags

#global #meta #command-generation
