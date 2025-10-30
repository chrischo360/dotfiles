#!/bin/bash

# Debug script to see what environment variables Claude Code actually passes

# Write all CLAUDE_* environment variables to a debug file
{
    echo "=== Claude Code Environment Variables ==="
    echo "Date: $(date)"
    env | grep CLAUDE_ || echo "No CLAUDE_* variables found"
    echo ""
    echo "All environment variables:"
    env | sort
} >> /tmp/claude-statusline-debug.log

# Run the normal statusline
exec ~/.claude/statusline.sh
