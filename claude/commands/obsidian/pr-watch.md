# pr-watch

**Skill:** `global:pr-watch`
**Type:** Global Command

## Purpose

Monitor GitHub PR CI checks in real-time.

## Uses

- gh CLI (PR status)
- scout CLI (`scout check`) ← **wraps this tool**

## Used By

- [[pr-submit]] ← **uses internally**
- [[pr-diagnose]] ← **uses internally**
- [[pr-automerge]] ← **uses internally**
- [[pr-create]] (suggested next step)
- User invoked manually

## Workflow

1. Get PR URL for current branch
2. Verify PR exists
3. Watch PR checks using scout CLI
   - Polls every 30 seconds
   - Shows real-time status
   - Desktop notifications on completion

## Options

- `--auto-merge` - Auto-merge PR when all checks pass
- `--once` - Check once and exit (no polling)

## Related Commands

- [[pr-submit]] - Validation + watch
- [[pr-automerge]] - Watch + auto-merge
- [[pr-diagnose]] - Watch + diagnose
- [[pr-dashboard]] - View all PRs

## Tags

#global #pr-workflow #monitoring #reusable-component
