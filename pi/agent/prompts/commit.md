---
description: Write a conventional commit message from staged changes
---
Write a git commit message for the staged changes (`git diff --cached`).

Format: `type(scope): short description`

Types: `feat`, `fix`, `refactor`, `test`, `chore`, `docs`, `style`, `perf`, `ci`

Rules:
- Subject line max 72 chars, imperative mood ("add" not "added")
- No period at end
- If non-obvious, add a blank line then a short body explaining *why*
- Scope = affected module/component/area (optional but preferred)

Examples:
```
feat(cart): add quantity stepper to line items
fix(checkout): handle undefined shipping methods on page load
refactor(api): extract product transformer to separate util
```

Output just the commit message, nothing else.
$@
