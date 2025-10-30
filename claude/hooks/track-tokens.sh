#!/bin/bash

# Token Tracking Hook for Claude Code
# Parses token usage warnings from Claude's responses and stores them
# Usage: Called automatically from PostAssistantMessage hook

# Get the project directory to create a unique token file per project
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
PROJECT_NAME=$(basename "$PROJECT_DIR")
# Sanitize project name for filename (replace / with _)
SAFE_PROJECT_NAME="${PROJECT_NAME//\//_}"
TOKEN_FILE="/tmp/claude-tokens-${SAFE_PROJECT_NAME}.txt"

# Read the assistant's message from stdin
MESSAGE=$(cat)

# Parse token usage from system warnings
# Pattern: "Token usage: 38082/200000; 159039 remaining"
if echo "$MESSAGE" | grep -q "Token usage:"; then
    # Extract the full token line
    TOKEN_LINE=$(echo "$MESSAGE" | grep -o "Token usage: [0-9]*/[0-9]*; [0-9]* remaining" | tail -1)

    if [ -n "$TOKEN_LINE" ]; then
        # Parse individual components
        USED=$(echo "$TOKEN_LINE" | sed -n 's/.*Token usage: \([0-9]*\)\/.*/\1/p')
        TOTAL=$(echo "$TOKEN_LINE" | sed -n 's/.*\/\([0-9]*\);.*/\1/p')
        REMAINING=$(echo "$TOKEN_LINE" | sed -n 's/.*; \([0-9]*\) remaining/\1/p')

        # Calculate percentage
        if [ "$TOTAL" -gt 0 ]; then
            PERCENTAGE=$(echo "scale=1; ($USED * 100) / $TOTAL" | bc)
        else
            PERCENTAGE=0
        fi

        # Format the output for statusline
        echo "📊 ${USED}/${TOTAL} (${PERCENTAGE}%) | ${REMAINING} left" > "$TOKEN_FILE"

        # Debug log (optional - comment out if not needed)
        # echo "[$(date)] Tracked tokens: ${USED}/${TOTAL}" >> /tmp/claude-token-debug.log
    fi
fi

# Always exit successfully so hook doesn't interfere with Claude
exit 0
