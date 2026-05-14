---
description: Profile and optimize performance issues
---
Investigate and fix this performance issue: $@

Process:
1. **Measure first** — find where time/memory is actually being spent (don't guess)
2. **Identify the bottleneck** — N+1 queries, unnecessary re-renders, large bundles, blocking I/O, etc.
3. **Check for quick wins** — memoization, lazy loading, caching, query optimization
4. **Propose changes** — concrete code changes with expected impact
5. **Verify** — how would we confirm the fix actually helped?

For React: check for unnecessary renders (React DevTools Profiler), missing `useMemo`/`useCallback`, heavy computations in render.
For API: check query plans, missing indexes, over-fetching, response size.
For bundle: check chunk sizes, tree-shaking, lazy splits.
