#!/bin/bash

# Claude Code Status Line Script
# Works with actually available environment variables

# Since Claude Code doesn't pass token usage via environment variables,
# we'll show what's actually available and useful

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
PROJECT_NAME=$(basename "$PROJECT_DIR")
ENTRYPOINT="${CLAUDE_CODE_ENTRYPOINT:-unknown}"
USE_VERTEX="${CLAUDE_CODE_USE_VERTEX:-0}"

# Determine model info
if [ "$USE_VERTEX" = "1" ]; then
    PROVIDER="GCP Vertex"
else
    PROVIDER="Anthropic API"
fi

# Show simple, useful status
echo "🤖 Claude Code | 📁 ${PROJECT_NAME} | ☁️  ${PROVIDER}"
