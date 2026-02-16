#!/bin/bash
# Display Buildkite status summary for tmux statusline
# Shows format: [BK: ⏳2 ✗1] or nothing if no active builds

CACHE_FILE="$HOME/.claude/buildkite-dashboard-cache.json"

# Check if cache file exists and monitoring session is running
if [[ ! -f "$CACHE_FILE" ]] || ! tmux has-session -t buildkite-monitor 2>/dev/null; then
  echo ""
  exit 0
fi

# Check if cache is stale (>2 minutes old)
if [[ $(uname) == "Darwin" ]]; then
  cache_age=$(($(date +%s) - $(stat -f %m "$CACHE_FILE")))
else
  cache_age=$(($(date +%s) - $(stat -c %Y "$CACHE_FILE")))
fi

if [[ $cache_age -gt 120 ]]; then
  # Stale cache, don't show
  echo ""
  exit 0
fi

# Count builds by status
success_count=$(jq '[.repos[] | select(.status == "SUCCESS")] | length' "$CACHE_FILE" 2>/dev/null || echo 0)
running_count=$(jq '[.repos[] | select(.status == "RUNNING")] | length' "$CACHE_FILE" 2>/dev/null || echo 0)
failed_count=$(jq '[.repos[] | select(.status == "FAILURE" or .status == "ERROR")] | length' "$CACHE_FILE" 2>/dev/null || echo 0)

# Build status string
status_parts=()
[[ $running_count -gt 0 ]] && status_parts+=("⏳$running_count")
[[ $failed_count -gt 0 ]] && status_parts+=("✗$failed_count")
[[ $success_count -gt 0 ]] && status_parts+=("✓$success_count")

# Only show if there are active builds
if [[ ${#status_parts[@]} -eq 0 ]]; then
  echo ""
else
  echo "BK: ${status_parts[*]}"
fi
