#!/bin/bash
# Buildkite Monitor Loop - Background monitoring script
# Runs continuously in dedicated tmux session

set -euo pipefail

# Configuration
INTERVAL="${BUILDKITE_MONITOR_INTERVAL:-30}"
LOG_FILE="${BUILDKITE_MONITOR_LOG:-$HOME/.claude/logs/buildkite-monitor.log}"
DASHBOARD_SCRIPT="$(dirname "$0")/buildkite_dashboard.sh"

# Ensure log directory exists
mkdir -p "$(dirname "$LOG_FILE")"

# Signal handling for graceful shutdown
cleanup() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') - Buildkite monitor stopped" >> "$LOG_FILE"
  exit 0
}

trap cleanup SIGTERM SIGINT

# Log startup
echo "$(date '+%Y-%m-%d %H:%M:%S') - Buildkite monitor started (interval: ${INTERVAL}s)" >> "$LOG_FILE"

# Main monitoring loop
while true; do
  # Clear screen and run dashboard
  clear

  if [[ -x "$DASHBOARD_SCRIPT" ]]; then
    if ! "$DASHBOARD_SCRIPT" 2>> "$LOG_FILE"; then
      echo "Error: Dashboard script failed (see $LOG_FILE for details)"
      sleep 5
    fi
  else
    echo "Error: Dashboard script not found or not executable: $DASHBOARD_SCRIPT"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Dashboard script not found: $DASHBOARD_SCRIPT" >> "$LOG_FILE"
    sleep 5
  fi

  # Wait for next iteration
  sleep "$INTERVAL"
done
