---
description: Refactor code for clarity, maintainability, and correctness
---
Refactor this code. Preserve all existing behavior — this is not a feature change.

Goals (focus on what's relevant):
- **Clarity** — rename things to say what they mean, extract complex logic into named functions
- **Duplication** — DRY up repeated patterns, but only if the abstraction is cleaner
- **Types** — add/tighten TypeScript types, remove `any`
- **Complexity** — simplify nested conditions, reduce cognitive load
- **Separation of concerns** — split mixed responsibilities

Constraints:
- Do not change public interfaces without flagging it
- Do not introduce new dependencies
- Keep diffs reviewable — don't refactor everything at once

Focus on: $@

Show the refactored code and briefly explain each significant change.
