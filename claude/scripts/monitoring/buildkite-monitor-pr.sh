#!/bin/bash
# Buildkite PR build monitoring with live progress visualization
# Usage: buildkite-monitor-pr.sh --pr <number> --context <name> [options]
#
# Exit codes:
#   0 - Build succeeded
#   1 - Build failed
#   2 - Timeout exceeded
#   3 - No build found

set -euo pipefail

# Default values
PR_NUMBER=""
CHECK_CONTEXT=""
TIMEOUT_MINUTES=35
NOTIFY_INTERVAL=5
TITLE="Buildkite Build Monitor"
ONCE_MODE=false

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --pr)
      PR_NUMBER="$2"
      shift 2
      ;;
    --context)
      CHECK_CONTEXT="$2"
      shift 2
      ;;
    --timeout)
      TIMEOUT_MINUTES="$2"
      shift 2
      ;;
    --notify-interval)
      NOTIFY_INTERVAL="$2"
      shift 2
      ;;
    --title)
      TITLE="$2"
      shift 2
      ;;
    --once)
      ONCE_MODE=true
      shift
      ;;
    *)
      echo "Unknown option: $1" >&2
      echo "Usage: $0 --pr <number> --context <name> [--timeout <min>] [--notify-interval <min>] [--title <text>] [--once]" >&2
      exit 1
      ;;
  esac
done

# Validate required parameters
if [[ -z "$PR_NUMBER" ]]; then
    echo "ERROR: --pr <number> is required" >&2
    exit 1
fi

if [[ -z "$CHECK_CONTEXT" ]]; then
    echo "ERROR: --context <name> is required" >&2
    exit 1
fi

# Get PR URL for display
PR_URL=$(gh pr view "$PR_NUMBER" --json url -q '.url' 2>/dev/null || echo "PR #$PR_NUMBER")

# Main monitoring configuration
MAX_ATTEMPTS=$TIMEOUT_MINUTES
ATTEMPT=1

# Display header
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Monitoring Buildkite Build"
echo "PR: $PR_URL"
echo "Context: $CHECK_CONTEXT"
if [ "$ONCE_MODE" = false ]; then
    echo "Max wait: $TIMEOUT_MINUTES minutes"
else
    echo "Mode: Single check (no polling)"
fi
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Monitoring loop
while [ $ATTEMPT -le $MAX_ATTEMPTS ]; do
    TIMESTAMP=$(date '+%H:%M:%S')

    # Get build status via gh CLI
    STATUS_JSON=$(gh pr view "$PR_NUMBER" --json statusCheckRollup \
      --jq ".statusCheckRollup[] | select(.context == \"$CHECK_CONTEXT\") | {state: .state, targetUrl: .targetUrl}" 2>/dev/null || echo "")

    # Check if build exists
    if [ -z "$STATUS_JSON" ]; then
        echo "[$TIMESTAMP] ⚠️  No build status found for context: $CHECK_CONTEXT"
        exit 3
    fi

    # Parse status
    STATE=$(echo "$STATUS_JSON" | jq -r '.state')
    BUILD_URL=$(echo "$STATUS_JSON" | jq -r '.targetUrl')

    # Display status with progress bar (only if polling)
    if [ "$ONCE_MODE" = false ]; then
        PROGRESS=$((ATTEMPT * 100 / MAX_ATTEMPTS))
        FILLED=$((PROGRESS / 5))
        EMPTY=$((20 - FILLED))
        BAR=$(printf "█%.0s" $(seq 1 $FILLED))$(printf "░%.0s" $(seq 1 $EMPTY))
        echo -ne "[$TIMESTAMP] Attempt $ATTEMPT/$MAX_ATTEMPTS [$BAR] $PROGRESS%% - State: $STATE\r"
    else
        echo "[$TIMESTAMP] State: $STATE"
    fi

    # Check for completion
    if [ "$STATE" = "SUCCESS" ]; then
        echo ""
        echo ""
        echo "✓ Buildkite build completed successfully!"
        echo "Build: $BUILD_URL"
        exit 0
    elif [ "$STATE" = "FAILURE" ]; then
        echo ""
        echo ""
        echo "✗ Buildkite build failed"
        echo "Build: $BUILD_URL"
        exit 1
    fi

    # Exit if once mode
    if [ "$ONCE_MODE" = true ]; then
        echo ""
        echo "Build still in progress: $STATE"
        echo "Build: $BUILD_URL"
        exit 0
    fi

    # Send notification at intervals
    if [ $((ATTEMPT % NOTIFY_INTERVAL)) -eq 0 ]; then
        if command -v terminal-notifier >/dev/null 2>&1; then
            terminal-notifier -title "$TITLE" \
                -message "Still waiting for build ($ATTEMPT/$MAX_ATTEMPTS min)" \
                -sound default 2>/dev/null || true
        fi
        echo ""
        echo "[$TIMESTAMP] 📢 Notification sent ($ATTEMPT/$MAX_ATTEMPTS minutes elapsed)"
    fi

    # Wait before next check
    if [ $ATTEMPT -lt $MAX_ATTEMPTS ]; then
        sleep 60
    fi

    ATTEMPT=$((ATTEMPT + 1))
done

# Timeout reached
echo ""
echo ""
echo "⏱️  Build exceeded $TIMEOUT_MINUTES minutes"
echo "Build: $BUILD_URL"
exit 2
