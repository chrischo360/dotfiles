#!/bin/bash

# Debug version of statusline that logs everything
# This helps us understand what Claude Code is actually sending

# Capture stdin to a file
INPUT=$(cat)

# Log the raw input
echo "=== STATUSLINE DEBUG CAPTURE ===" >> /tmp/statusline-debug.log
echo "Timestamp: $(date)" >> /tmp/statusline-debug.log
echo "Input JSON:" >> /tmp/statusline-debug.log
echo "$INPUT" >> /tmp/statusline-debug.log
echo "" >> /tmp/statusline-debug.log

# Extract transcript path
TRANSCRIPT_PATH=$(echo "$INPUT" | grep -o '"transcript_path"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*"\([^"]*\)".*/\1/')
echo "Extracted transcript_path: $TRANSCRIPT_PATH" >> /tmp/statusline-debug.log

# Check if file exists
if [ -n "$TRANSCRIPT_PATH" ]; then
    if [ -f "$TRANSCRIPT_PATH" ]; then
        echo "Transcript file EXISTS" >> /tmp/statusline-debug.log
        echo "Last 5 token usage lines:" >> /tmp/statusline-debug.log
        grep "Token usage:" "$TRANSCRIPT_PATH" 2>/dev/null | tail -5 >> /tmp/statusline-debug.log
    else
        echo "Transcript file DOES NOT EXIST" >> /tmp/statusline-debug.log
    fi
else
    echo "No transcript_path in input JSON" >> /tmp/statusline-debug.log
fi

echo "==================" >> /tmp/statusline-debug.log
echo "" >> /tmp/statusline-debug.log

# Now run the actual statusline script
echo "$INPUT" | /Users/cc446g/dotfiles/claude/statusline.sh
