#!/bin/bash

# Continuous monitoring loop for Buildkite builds
# This script will run indefinitely, checking builds every 60 seconds

BUILDS=(
    "https://buildkite.com/wayfair/block-builder-api/builds/41851|block-builder-api #41851"
)

echo "Starting continuous build monitoring..."
echo "Monitoring ${#BUILDS[@]} build(s)"
echo "Press Ctrl+C to stop"
echo ""

# Run forever
while true; do
    TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$TIMESTAMP] CHECK_BUILDS_NOW"

    # Sleep for 60 seconds before next check
    sleep 60
done
