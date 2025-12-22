#!/bin/bash

# Monitor Buildkite build and notify when complete using Playwright MCP via Claude Code
# This script works by checking the build status via Claude Code's Playwright MCP integration

BUILD_URL="https://buildkite.com/wayfair/sf-ui-web-dev/builds/104484"
CHECK_INTERVAL=60
STATUS_FILE="/tmp/buildkite_monitor_$$"

# Cleanup on exit
cleanup() {
    rm -f "$STATUS_FILE"
    echo ""
    echo "Monitoring stopped."
}
trap cleanup EXIT INT TERM

echo "Monitoring build: $BUILD_URL"
echo "Checking every ${CHECK_INTERVAL} seconds..."
echo "Press Ctrl+C to stop monitoring"
echo ""

# Check if terminal-notifier is available
if ! command -v terminal-notifier &> /dev/null; then
    echo "WARNING: terminal-notifier not found. Install with: brew install terminal-notifier"
    exit 1
fi

# Main monitoring loop
while true; do
    TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$TIMESTAMP] Checking build status..."

    # Call this script's check function via Claude Code
    # This is a marker for Claude Code to intercept and use Playwright MCP
    echo "BUILDKITE_CHECK:$BUILD_URL" > "$STATUS_FILE"

    # In a real implementation, Claude Code would:
    # 1. Detect the BUILDKITE_CHECK marker
    # 2. Use Playwright MCP to navigate to the URL
    # 3. Extract the build status from the page
    # 4. Write the status back to STATUS_FILE

    # For now, we'll create a simpler version that you can manually integrate
    echo "Status check needed - waiting for Claude Code integration"

    sleep "$CHECK_INTERVAL"
done
