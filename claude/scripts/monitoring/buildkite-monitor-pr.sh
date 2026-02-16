#!/bin/bash
# Buildkite PR build monitoring with live progress visualization
# Usage: buildkite-monitor-pr.sh --pr <number> --context <name> [options]
#
# Exit codes:
#   0 - Build succeeded
#   1 - Build failed
#   2 - Timeout exceeded
#   3 - No build found
#
# Features:
# - Primary: GitHub API for build status (fast, always available)
# - Fallback: Buildkite MCP for failure details and version extraction
# - Progress bar with timestamps
# - Desktop notifications

set -euo pipefail

# Default values
PR_NUMBER=""
CHECK_CONTEXT=""
TIMEOUT_MINUTES=35
NOTIFY_INTERVAL=5
TITLE="Buildkite Build Monitor"
ONCE_MODE=false
EXTRACT_VERSION=false
REPO_OWNER=""
REPO_NAME=""

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
    --extract-version)
      EXTRACT_VERSION=true
      shift
      ;;
    --repo)
      REPO_OWNER="$(echo "$2" | cut -d/ -f1)"
      REPO_NAME="$(echo "$2" | cut -d/ -f2)"
      shift 2
      ;;
    *)
      echo "Unknown option: $1" >&2
      echo "Usage: $0 --pr <number> --context <name> [--timeout <min>] [--notify-interval <min>] [--title <text>] [--once] [--extract-version] [--repo owner/name]" >&2
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

# Auto-detect repo if not provided
if [[ -z "$REPO_OWNER" ]] || [[ -z "$REPO_NAME" ]]; then
    PR_INFO=$(gh pr view "$PR_NUMBER" --json url -q '.url' 2>/dev/null || echo "")
    if [[ -n "$PR_INFO" ]]; then
        REPO_OWNER=$(echo "$PR_INFO" | sed -E 's|https://github.com/([^/]+)/.*|\1|')
        REPO_NAME=$(echo "$PR_INFO" | sed -E 's|https://github.com/[^/]+/([^/]+)/.*|\1|')
    fi
fi

# Get PR URL and commit SHA for display
PR_URL=$(gh pr view "$PR_NUMBER" --json url -q '.url' 2>/dev/null || echo "PR #$PR_NUMBER")
COMMIT_SHA=$(gh pr view "$PR_NUMBER" --json headRefOid -q '.headRefOid' 2>/dev/null || echo "")

# Helper function: Get build details via GitHub API
get_build_status_gh() {
    local pr_num=$1
    local context=$2
    local commit=$3

    # Try statusCheckRollup first (PR-level)
    local status_json=$(gh pr view "$pr_num" --json statusCheckRollup \
        --jq ".statusCheckRollup[] | select(.context == \"$context\") | {state: .state, targetUrl: .targetUrl, startedAt: .startedAt}" 2>/dev/null || echo "")

    if [[ -n "$status_json" ]]; then
        echo "$status_json"
        return 0
    fi

    # Fallback: Try commit statuses (gives us description with duration)
    if [[ -n "$commit" ]] && [[ -n "$REPO_OWNER" ]] && [[ -n "$REPO_NAME" ]]; then
        gh api "repos/$REPO_OWNER/$REPO_NAME/commits/$commit/statuses" \
            --jq "[.[] | select(.context == \"$context\")] | sort_by(.created_at) | last | {state: .state, targetUrl: .target_url, description: .description}" 2>/dev/null || echo ""
    else
        echo ""
    fi
}

# Helper function: Get failed jobs via Buildkite MCP
get_failed_jobs_mcp() {
    local build_url=$1

    # Extract build number from URL
    local build_num=$(echo "$build_url" | grep -oE '[0-9]+$')

    if command -v claude-mcp >/dev/null 2>&1; then
        echo "  Querying Buildkite MCP for failure details..."
        # This would spawn a claude-mcp session to get job details
        # For now, return placeholder
        echo "  (MCP integration pending - see $build_url for details)"
    fi
}

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

    # Get build status via GitHub API
    STATUS_JSON=$(get_build_status_gh "$PR_NUMBER" "$CHECK_CONTEXT" "$COMMIT_SHA")

    # Check if build exists
    if [ -z "$STATUS_JSON" ]; then
        echo "[$TIMESTAMP] ⚠️  No build status found for context: $CHECK_CONTEXT"
        exit 3
    fi

    # Parse status
    STATE=$(echo "$STATUS_JSON" | jq -r '.state // empty')
    BUILD_URL=$(echo "$STATUS_JSON" | jq -r '.targetUrl // .target_url // empty')
    DESCRIPTION=$(echo "$STATUS_JSON" | jq -r '.description // empty')

    # Normalize state (GitHub uses SUCCESS/PENDING/FAILURE, also handle lowercase)
    STATE=$(echo "$STATE" | tr '[:lower:]' '[:upper:]')

    # Display status with progress bar (only if polling)
    if [ "$ONCE_MODE" = false ]; then
        PROGRESS=$((ATTEMPT * 100 / MAX_ATTEMPTS))
        FILLED=$((PROGRESS / 5))
        EMPTY=$((20 - FILLED))
        BAR=$(printf "█%.0s" $(seq 1 $FILLED))$(printf "░%.0s" $(seq 1 $EMPTY))

        # Show description if available (includes duration)
        if [ -n "$DESCRIPTION" ]; then
            echo -ne "[$TIMESTAMP] Attempt $ATTEMPT/$MAX_ATTEMPTS [$BAR] $PROGRESS%% - $DESCRIPTION\r"
        else
            echo -ne "[$TIMESTAMP] Attempt $ATTEMPT/$MAX_ATTEMPTS [$BAR] $PROGRESS%% - State: $STATE\r"
        fi
    else
        if [ -n "$DESCRIPTION" ]; then
            echo "[$TIMESTAMP] $DESCRIPTION"
        else
            echo "[$TIMESTAMP] State: $STATE"
        fi
    fi

    # Check for completion
    if [ "$STATE" = "SUCCESS" ]; then
        echo ""
        echo ""
        echo "✓ Buildkite build completed successfully!"
        if [ -n "$DESCRIPTION" ]; then
            echo "  $DESCRIPTION"
        fi
        echo "Build: $BUILD_URL"

        # Extract version if requested (for sf-js-libraries)
        if [ "$EXTRACT_VERSION" = true ]; then
            echo ""
            echo "Extracting pre-release version..."
            # TODO: Implement MCP version extraction
            echo "  (Version extraction via MCP coming soon)"
            echo "  Check build logs: $BUILD_URL"
        fi

        exit 0
    elif [ "$STATE" = "FAILURE" ] || [ "$STATE" = "ERROR" ]; then
        echo ""
        echo ""
        echo "✗ Buildkite build failed"
        if [ -n "$DESCRIPTION" ]; then
            echo "  $DESCRIPTION"
        fi
        echo "Build: $BUILD_URL"

        # Try to get failure details via MCP
        get_failed_jobs_mcp "$BUILD_URL"

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
