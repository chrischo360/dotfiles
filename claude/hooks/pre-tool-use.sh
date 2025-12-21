#!/bin/bash
# Hook: PreToolUse - Track which tool Claude is about to use
# Maps tool names to action types for display

# Read JSON input from stdin
input=$(cat)

# Parse tool_name from JSON
tool_name=$(echo "$input" | jq -r '.tool_name // ""')

echo "[$(date '+%H:%M:%S')] PreToolUse hook fired - tool: $tool_name" >> ~/.claude/hook-debug.log

# Map tool names to action types
action=""
case "$tool_name" in
  Read|Glob)
    action="reading"
    ;;
  Grep)
    action="searching"
    ;;
  Edit|Write|NotebookEdit)
    action="editing"
    ;;
  Bash)
    action="running"
    ;;
  Task)
    action="delegating"
    ;;
  AskUserQuestion)
    # Special case: waiting state instead of active
    echo "[$(date '+%H:%M:%S')] AskUserQuestion about to fire - setting state to waiting" >> ~/.claude/hook-debug.log
    $DOTFILES_DIR/claude/scripts/update-session-state.sh waiting
    exit 0
    ;;
  WebFetch|WebSearch)
    action="fetching"
    ;;
  *)
    # Other tools: generic active state
    action=""
    ;;
esac

# Update session state with tool-specific action
if [[ -n "$action" ]]; then
  echo "[$(date '+%H:%M:%S')] Setting action to: $action" >> ~/.claude/hook-debug.log
  ~/dotfiles/claude/scripts/update-session-state.sh active "$action"
fi
