---
description: Monitor Buildkite build status with live progress and notifications
---
Monitor Buildkite build status with live progress and notifications.

Intelligent Buildkite monitoring that auto-detects PR context, monitors build progress with visual feedback, and handles MCP-aware strategy selection.

## Usage

```bash
# Auto-detect PR and context from current branch
/buildkite-watch

# Explicit PR number
/buildkite-watch --pr 5428

# Custom timeout (default: 35 minutes)
/buildkite-watch --pr 5428 --timeout 10

# Single check, no polling
/buildkite-watch --once

# Different context
/buildkite-watch --pr 1234 --context "buildkite/sf-js-libraries"

# Force foreground monitor (skip dashboard)
/buildkite-watch --foreground
```

## Parameters

All parameters are optional with intelligent defaults:

- `--pr <number>` - PR number (auto-detects from current branch)
- `--pr-url <url>` - Full PR URL (alternative to --pr)
- `--context <name>` - Buildkite check context (auto-detects from repo)
- `--timeout <minutes>` - Max wait time (default: 35)
- `--notify <minutes>` - Notification interval (default: 5)
- `--once` - Single check, no polling
- `--foreground` - Force foreground monitor (skip dashboard check)

## Steps

### 1. Parse Arguments and Auto-Detection

Parse user-provided arguments or auto-detect from current context.

**Auto-detect PR number** (if not provided):
```bash
gh pr view --json number -q '.number' 2>/dev/null
```

If no PR found, exit with error:
```
❌ No PR found for current branch.
Create one first: gh pr create
```

**Auto-detect Buildkite context** (if not provided):

Detect from repository remote URL:
```bash
REPO_NAME=$(git remote -v | head -1 | grep -oE '\/[^/]+\.git' | sed 's/[/.]//g')
CHECK_CONTEXT="buildkite/$REPO_NAME"
```

Common contexts:
- `buildkite/block-builder-api`
- `buildkite/sf-js-libraries`
- `buildkite/sf-ui-web`
- `buildkite/sf-ui-cart-and-checkout`

**Set defaults:**
- Timeout: 35 minutes (standard for backend services)
- Notify interval: 5 minutes
- Once mode: disabled (poll until completion)

### 2. MCP Strategy Detection

Check if MCP tools are available for enhanced monitoring.

**Check for Buildkite MCP:**
```
Check if mcp__buildkite__* tools available in current session
```

**Check for GitHub MCP:**
```
Check if mcp__github__* tools available in current session
```

**Display MCP status:**

If MCP tools NOT available, show informational message:
```
ℹ️  MCP servers not detected in current session.

For best results, Buildkite monitoring works better with MCP:
  • buildkite       - Direct build status and job logs
  • github_wayfair  - Enhanced PR check monitoring

Continuing with gh CLI fallback.

────────────────────────────────────────────────────────────────
To use MCP servers next time, exit and run:

  claude-mcp --servers "buildkite,github_wayfair" /buildkite-watch

────────────────────────────────────────────────────────────────
```

**Do not attempt to run `claude-mcp` from within this session** - it's a shell function only available externally.

**Continue automatically** - MCP is optional, gh CLI fallback is reliable.

### 3. Check for Dashboard Session

Before executing foreground monitor, check if dashboard session is running.

**Skip if `--foreground` flag provided.**

**Check for monitoring session:**
```bash
tmux has-session -t buildkite-monitor 2>/dev/null
```

**If session exists:**

Show current status from cache and offer to view:
```
✓ Buildkite dashboard already monitoring this repo.

Current status for block-builder-api:
  PR #5428 (ccho_hfc_ui_gem_content_ph_PGL-947)
  ⏳ RUNNING - Build #46436 (2m 15s ago)
  https://buildkite.com/wayfair/block-builder-api/builds/46436

View dashboard: tmux attach -t buildkite-monitor
Or use: Prefix + s to switch sessions
```

Exit cleanly (no need for foreground monitor).

**If session does NOT exist:**

Offer to start dashboard:
```
No dashboard running. Would you like to:
  1. Start persistent dashboard (monitors all repos, non-blocking)
  2. Run foreground monitor (blocks terminal, this repo only)

Choice (1/2):
```

- If `1`: Start dashboard session and exit
  ```bash
  ~/dotfiles/scripts/tmux/buildkite_monitor_session.sh start
  ```

- If `2`: Continue to foreground monitor (next step)

### 4. Execute Monitoring

Delegate to utility script for actual polling and progress visualization.

**Script path:**
```bash
SCRIPT_PATH="$HOME/dotfiles/claude/scripts/monitoring/buildkite-monitor-pr.sh"
```

**Verify script exists:**
```bash
if [ ! -x "$SCRIPT_PATH" ]; then
    echo "❌ Monitoring script not found or not executable: $SCRIPT_PATH"
    exit 1
fi
```

**Build command arguments:**
```bash
ARGS=(
    --pr "$PR_NUMBER"
    --context "$CHECK_CONTEXT"
    --timeout "$TIMEOUT_MINUTES"
    --notify-interval "$NOTIFY_INTERVAL"
)

# Add --title for better notifications
TITLE="Buildkite: $REPO_NAME"
ARGS+=(--title "$TITLE")
```

**Execute monitoring:**
```bash
"$SCRIPT_PATH" "${ARGS[@]}"
EXIT_CODE=$?
```

The script runs in foreground, displaying:
- Live progress bar with percentage
- Timestamps on each check
- Desktop notifications every N minutes
- Build URL on completion

### 5. Handle Exit Codes

The monitoring script returns specific exit codes for different outcomes.

**Exit Code 0 - SUCCESS:**
```
✓ Build completed successfully
```

Proceed to next step in workflow (if called from prepublish) or exit cleanly.

**Exit Code 1 - FAILURE:**
```
✗ Build failed
Build URL: <url>
```

Ask user to continue or exit:
```
Build failed. GraphQL validation may have completed anyway.
Continue to next step? (y/n)
```

- If `y`: Continue to next workflow step
- If `n`: Exit with failure, user can inspect build manually

**Exit Code 2 - TIMEOUT:**
```
⏱️  Build exceeded <timeout> minutes
Build URL: <url>
```

Ask user what to do:
```
Build exceeded timeout. Options:
1. wait   - Continue waiting (extend timeout)
2. skip   - Proceed anyway (feature variant may not be ready)
3. exit   - Stop and inspect manually

Choice (wait/skip/exit):
```

- If `wait`: Re-invoke monitoring script with extended timeout (+20 minutes)
- If `skip`: Continue to next step (may fail if build artifacts not ready)
- If `exit`: Exit cleanly with build URL

**Exit Code 3 - NO BUILD FOUND:**
```
⚠️  No Buildkite build found for context: <context>
```

This usually means:
- No files changed that trigger Buildkite
- PR created before build started
- Wrong context name

Ask user:
```
No Buildkite build detected. This may mean:
- No schema/code changes that trigger builds
- Build hasn't started yet

Continue anyway? (y/n)
```

- If `y`: Continue (may fail downstream if build artifacts needed)
- If `n`: Exit

**Any other exit code:**
```
❌ Unexpected error from monitoring script (exit code: <code>)
```

Exit with failure.

## What This Does

- **Auto-detects** PR number from current branch via `gh pr view`
- **Auto-detects** Buildkite context from repository name
- **Checks** for MCP availability and informs user
- **Delegates** to bash script for fast, efficient polling
- **Displays** live progress bar with timestamps
- **Sends** desktop notifications at regular intervals
- **Returns** structured exit codes for workflow integration

## Integration with Other Commands

This command is designed to be reusable across workflows:

**From prepublish skills:**
```markdown
Use Skill tool to invoke buildkite-watch:
- skill: "buildkite-watch"
- args: "" (auto-detect everything)
```

**From custom workflows:**
```bash
/buildkite-watch --pr 1234 --timeout 10
```

## Exit Code Summary

| Code | Meaning | Action |
|------|---------|--------|
| 0 | Build succeeded | Continue workflow |
| 1 | Build failed | Ask to continue or exit |
| 2 | Timeout exceeded | Ask to wait/skip/exit |
| 3 | No build found | Warn and ask to continue |
| Other | Script error | Exit with error |

## Error Handling

- Script not found → Show path and exit
- No PR detected → Show instructions to create PR
- gh CLI error → Show error and exit
- terminal-notifier missing → Continue without notifications (non-fatal)

## Notes

- Works for any Buildkite-monitored GitHub repository
- Requires `gh` CLI authentication
- Requires `jq` for JSON parsing
- `terminal-notifier` optional (macOS only, for notifications)
- Script runs in foreground (output visible to user)
- Can be interrupted with Ctrl+C
