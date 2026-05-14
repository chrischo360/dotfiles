---
description: Plan a migration or upgrade (deps, frameworks, APIs)
---
Plan a migration for: $@

Before planning, read the relevant code to understand the current state.

Deliver:
1. **Current state** — what we have now, where it's used
2. **Target state** — what we're moving to, and why
3. **Breaking changes** — what will break, what needs updating
4. **Migration steps** — ordered, atomic steps that can be reviewed separately
5. **Rollback plan** — how to undo if something goes wrong
6. **Risk areas** — what's most likely to cause problems

Be concrete — reference actual files, functions, and patterns you find in the codebase.
