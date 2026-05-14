---
description: Review code for bugs, security, and quality issues
---
Review this code thoroughly. Check for:

- **Bugs & logic errors** — off-by-ones, null/undefined, wrong assumptions
- **Type safety** — missing types, unsafe casts, `any` abuse
- **Error handling** — uncaught exceptions, unhandled promise rejections, missing edge cases
- **Security** — XSS, injection, exposed secrets, unsafe user input
- **Performance** — unnecessary re-renders, N+1 queries, missing memoization
- **Readability** — unclear naming, missing comments on complex logic
- **Test coverage** — untested branches, missing edge case tests

Focus on: $@

Be specific — point to exact lines, explain why it's a problem, and suggest a fix.
