#!/bin/bash
# Debug helper: Show current Claude session state and recent hook activity

echo "=== Current Session State ==="
if [[ -f ~/.claude/session-state.json ]]; then
  cat ~/.claude/session-state.json | jq '.'
else
  echo "State file not found"
fi

echo ""
echo "=== Recent Hook Activity (last 10 entries) ==="
if [[ -f ~/.claude/hook-debug.log ]]; then
  tail -10 ~/.claude/hook-debug.log
else
  echo "No hook activity logged yet"
fi

echo ""
echo "=== Current tmux statusline output ==="
~/dotfiles/tmux/scripts/claude_status.sh
