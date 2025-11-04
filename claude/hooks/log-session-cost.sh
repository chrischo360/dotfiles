#!/bin/bash

# Log session costs to a cumulative tracking file
# Triggered on SessionEnd

LOG_FILE="$HOME/.claude/session-costs.csv"

# Initialize log file if it doesn't exist
if [ ! -f "$LOG_FILE" ]; then
    echo "timestamp,session_id,project,tokens_used,estimated_cost,model" > "$LOG_FILE"
fi

# Extract session info from environment or defaults
SESSION_ID="${CLAUDE_SESSION_ID:-unknown}"
PROJECT="${CLAUDE_PROJECT_DIR:-$(pwd)}"
TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")
MODEL="sonnet-4.5"

# GCP Vertex AI pricing
INPUT_PRICE=3.00
OUTPUT_PRICE=15.00

# Try to get token usage from debug file
if [ -n "$SESSION_ID" ]; then
    DEBUG_FILE="$HOME/.claude/debug/${SESSION_ID}.txt"
    if [ -f "$DEBUG_FILE" ]; then
        # Try to extract token count from debug output
        TOKENS=$(grep -o "Summarizing.*~[0-9]* tokens" "$DEBUG_FILE" | tail -1 | grep -o "[0-9]*" | tail -1)
    fi
fi

# Default if we couldn't extract
TOKENS=${TOKENS:-0}

if [ "$TOKENS" -gt 0 ]; then
    # Estimate 70% input, 30% output
    INPUT_TOKENS=$(echo "scale=0; $TOKENS * 0.7 / 1" | bc)
    OUTPUT_TOKENS=$(echo "scale=0; $TOKENS * 0.3 / 1" | bc)

    # Calculate cost
    INPUT_COST=$(echo "scale=6; $INPUT_TOKENS * $INPUT_PRICE / 1000000" | bc)
    OUTPUT_COST=$(echo "scale=6; $OUTPUT_TOKENS * $OUTPUT_PRICE / 1000000" | bc)
    TOTAL_COST=$(echo "scale=4; $INPUT_COST + $OUTPUT_COST" | bc)

    # Log to CSV
    echo "$TIMESTAMP,$SESSION_ID,$PROJECT,$TOKENS,$TOTAL_COST,$MODEL" >> "$LOG_FILE"
fi

exit 0
