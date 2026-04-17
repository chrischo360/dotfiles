---
description: Write tests for existing code
---
Write tests for this code. Read the existing test files first to match the project's style, framework, and conventions.

Coverage goals:
- **Happy path** — normal expected behavior
- **Edge cases** — empty arrays, null/undefined, zero, boundary values
- **Error cases** — what happens when things fail?
- **Integration points** — if it calls external things, mock them properly

Guidelines:
- Test behavior, not implementation — don't test internals
- One assertion per test (or one concept per test)
- Descriptive test names: `it('returns empty array when no items match filter')`
- Don't over-mock — only mock what you must (I/O, time, randomness)

Focus on: $@
