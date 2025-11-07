#!/bin/bash

# Continuous build monitoring script
# This script will be run by you manually and I'll help interpret the results

BUILD_1_URL="https://buildkite.com/wayfair/block-builder-api/builds/41851"
BUILD_1_NAME="block-builder-api #41851"

BUILD_2_URL="https://buildkite.com/wayfair/php/builds/814043"
BUILD_2_NAME="php #814043"

echo "Monitoring 2 builds:"
echo "1. $BUILD_1_NAME"
echo "2. $BUILD_2_NAME"
echo ""
echo "I (Claude) will check these every 60 seconds and notify you when they complete."
echo "You can press Ctrl+C to stop this script at any time."
echo ""

# Note: The actual checking will be done by Claude using Playwright MCP
# This script is just a placeholder to remind us what we're monitoring
