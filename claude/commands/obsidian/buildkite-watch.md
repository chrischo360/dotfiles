# buildkite-watch

**Skill:** `global:buildkite-watch`
**Type:** Global Command

## Purpose

Monitor Buildkite build status with live progress and notifications.

## Uses

- gh CLI (PR detection)
- Monitoring script (`~/dotfiles/claude/scripts/monitoring/buildkite-monitor-pr.sh`)
- scout CLI (optional, fallback)

## Used By

- [[prepublish-block-builder-api]] ← **invoked to monitor builds**
- [[prepublish-sf-js-libraries]] ← **invoked to monitor builds**
- User invoked manually

## Workflow

```
1. Parse arguments and auto-detection
   - Auto-detect PR number (if not provided)
   - Auto-detect Buildkite context from repo
   - Set defaults (timeout: 35 min, notify: 5 min)

2. MCP strategy detection
   - Check for Buildkite MCP
   - Check for GitHub MCP
   - Show informational message if not available
   - Continue with gh CLI fallback

3. Execute monitoring
   - Verify script exists
   - Build command arguments
   - Execute monitoring script
   - Display live progress

4. Handle exit codes
   - 0: Success → continue
   - 1: Failure → ask to continue or exit
   - 2: Timeout → ask to wait/skip/exit
   - 3: No build found → warn and ask
```

## Parameters

All optional with intelligent defaults:

- `--pr <number>` - PR number (auto-detects from current branch)
- `--pr-url <url>` - Full PR URL
- `--context <name>` - Buildkite check context (auto-detects from repo)
- `--timeout <minutes>` - Max wait time (default: 35)
- `--notify <minutes>` - Notification interval (default: 5)
- `--once` - Single check, no polling

## Exit Codes

| Code | Meaning | Action |
|------|---------|--------|
| 0 | Build succeeded | Continue workflow |
| 1 | Build failed | Ask to continue or exit |
| 2 | Timeout exceeded | Ask to wait/skip/exit |
| 3 | No build found | Warn and ask to continue |

## Usage Examples

```bash
# Auto-detect PR and context
/buildkite-watch

# Explicit PR number
/buildkite-watch --pr 5428

# Custom timeout
/buildkite-watch --pr 5428 --timeout 10

# Single check
/buildkite-watch --once

# Different context
/buildkite-watch --pr 1234 --context "buildkite/sf-js-libraries"
```

## Related Commands

- [[prepublish-block-builder-api]] - Uses this for build monitoring
- [[prepublish-sf-js-libraries]] - Uses this for build monitoring

## Tags

#global #monitoring #buildkite #reusable-component
