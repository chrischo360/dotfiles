#!/bin/bash
# Buildkite monitoring session management

SESSION_NAME="buildkite-monitor"
MONITOR_SCRIPT="$HOME/dotfiles/tmux/scripts/buildkite_monitor_loop.sh"
CACHE_FILE="${BUILDKITE_MONITOR_CACHE:-$HOME/.claude/buildkite-dashboard-cache.json}"

start_monitor() {
  # Check if session already exists
  if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
    echo "Buildkite monitor already running (session: $SESSION_NAME)"
    echo "Attach with: tmux attach -t $SESSION_NAME"
    echo "Or use: Prefix + s to switch"
    return 0
  fi

  # Verify monitor script exists
  if [[ ! -x "$MONITOR_SCRIPT" ]]; then
    echo "Error: Monitor script not found or not executable: $MONITOR_SCRIPT"
    return 1
  fi

  # Create detached session
  tmux new-session -d -s "$SESSION_NAME" "$MONITOR_SCRIPT"

  echo "Buildkite monitor started (session: $SESSION_NAME)"
  echo "View with: tmux attach -t $SESSION_NAME"
}

stop_monitor() {
  if ! tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
    echo "Buildkite monitor not running"
    return 1
  fi

  tmux kill-session -t "$SESSION_NAME"
  echo "Buildkite monitor stopped"
}

toggle_monitor() {
  if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
    stop_monitor
  else
    start_monitor
  fi
}

status_monitor() {
  if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
    echo "✓ Buildkite monitor running (session: $SESSION_NAME)"

    # Show last update time if cache exists
    if [[ -f "$CACHE_FILE" ]]; then
      if [[ $(uname) == "Darwin" ]]; then
        local last_update=$(stat -f "%Sm" -t "%H:%M:%S" "$CACHE_FILE" 2>/dev/null || echo "unknown")
      else
        local last_update=$(stat -c "%y" "$CACHE_FILE" 2>/dev/null | cut -d' ' -f2 | cut -d'.' -f1 || echo "unknown")
      fi
      echo "  Last update: $last_update"
    fi
  else
    echo "✗ Buildkite monitor not running"
    echo "  Start with: buildkite_monitor start"
  fi
}

# Main command dispatch
case "${1:-status}" in
  start)
    start_monitor
    ;;
  stop)
    stop_monitor
    ;;
  toggle)
    toggle_monitor
    ;;
  status)
    status_monitor
    ;;
  *)
    echo "Usage: buildkite_monitor {start|stop|toggle|status}"
    exit 1
    ;;
esac
