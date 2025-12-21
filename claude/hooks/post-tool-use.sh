#!/bin/bash
# Hook: PostToolUse - Detect when AskUserQuestion is used
# Sets state to "waiting_for_input" when Claude asks a question

# Read JSON input from stdin
input=$(cat)

# Parse tool_name from JSON
tool_name=$(echo "$input" | jq -r '.tool_name // ""')

echo "[$(date '+%H:%M:%S')] PostToolUse hook fired - tool: $tool_name" >> ~/.claude/hook-debug.log

# If AskUserQuestion was used, mark session as waiting for input
if [[ "$tool_name" == "AskUserQuestion" ]]; then
  echo "[$(date '+%H:%M:%S')] AskUserQuestion detected - setting state to waiting" >> ~/.claude/hook-debug.log
  ~/dotfiles/claude/scripts/update-session-state.sh waiting
fi
