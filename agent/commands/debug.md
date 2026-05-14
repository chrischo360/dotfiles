---
description: Systematic debugging - find root cause, not just symptoms
---
Debug this issue systematically. Do NOT guess — investigate first.

**Problem:** $@

Steps:
1. Read the relevant code paths end-to-end before forming hypotheses
2. Identify all places this could fail — list them
3. Check actual error messages, stack traces, and logs (`git log`, console output, network responses)
4. Narrow down to the root cause — what assumption is wrong?
5. Propose a fix with explanation of *why* it works
6. Note any related issues you spotted while investigating

Do not fix anything until you've confirmed the root cause.
