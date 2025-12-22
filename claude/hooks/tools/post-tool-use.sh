#!/bin/bash
# Hook: PostToolUse - Tool completed, preserve action for visibility
# Don't clear action yet - wait until Stop to clear (better visibility)

# Read JSON input from stdin
input=$(cat)

# Parse tool_name from JSON
tool_name=$(echo "$input" | jq -r '.tool_name // ""')

echo "[$(date '+%H:%M:%S')] PostToolUse hook fired - tool: $tool_name (preserving action)" >> ~/.claude/hook-debug.log

# No action needed - action stays visible until Stop hook clears it
# This makes icons visible longer instead of flashing by too quickly
