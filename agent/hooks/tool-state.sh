#!/bin/bash
# Shared tool hook mapper for agent tmux statuslines.
# Reads hook JSON from stdin and maps tool_name to session-state action.
# Usage: tool-state.sh <agent>

AGENT="${1:-Agent}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null && pwd)"
input=$(cat)
tool_name=$(echo "$input" | jq -r '.tool_name // .toolName // ""' 2>/dev/null)

action=""
case "$tool_name" in
  Read|Glob|read|find|ls)
    action="reading"
    ;;
  Grep|grep)
    action="searching"
    ;;
  Edit|Write|NotebookEdit|edit|write)
    action="editing"
    ;;
  Bash|bash)
    action="running"
    ;;
  Task)
    action="delegating"
    ;;
  AskUserQuestion)
    "$SCRIPT_DIR/session-state.sh" "$AGENT" waiting
    exit 0
    ;;
  WebFetch|WebSearch|web_fetch|web_search)
    action="fetching"
    ;;
  *)
    action=""
    ;;
esac

if [[ -n "$action" ]]; then
  "$SCRIPT_DIR/session-state.sh" "$AGENT" active "$action"
else
  "$SCRIPT_DIR/session-state.sh" "$AGENT" active
fi
