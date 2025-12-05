#!/bin/bash

# Helper script to extract build status from Buildkite page snapshot
# This will be called by the monitoring loop

# The build status text we're looking for:
# "Running for X" = still running
# "Passed" = build succeeded
# "Failed" = build failed
# "Canceled" = build was canceled

STATUS_TEXT="$1"

if echo "$STATUS_TEXT" | grep -qi "passed"; then
    echo "passed"
elif echo "$STATUS_TEXT" | grep -qi "failed"; then
    echo "failed"
elif echo "$STATUS_TEXT" | grep -qi "canceled"; then
    echo "canceled"
elif echo "$STATUS_TEXT" | grep -qi "running for"; then
    echo "running"
else
    echo "unknown"
fi
