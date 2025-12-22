#!/bin/bash
# Hook: Stop - Called when Claude finishes responding
# Sets state to idle unless already waiting_for_input (from AskUserQuestion)

echo "[$(date '+%H:%M:%S')] Stop hook fired" >> ~/.claude/hook-debug.log

STATE_FILE="$HOME/.claude/session-state.json"
PANE_ID="$TMUX_PANE"

# Check current state
if [[ -f "$STATE_FILE" && -n "$PANE_ID" ]]; then
  current_status=$(jq -r --arg pane "$PANE_ID" '.sessions[$pane].status // ""' "$STATE_FILE" 2>/dev/null)

  # Only set to idle if not already waiting_for_input
  if [[ "$current_status" != "waiting_for_input" ]]; then
    echo "[$(date '+%H:%M:%S')] Setting to idle (current: $current_status)" >> ~/.claude/hook-debug.log
    $DOTFILES_DIR/claude/scripts/state/update-session-state.sh idle
  else
    echo "[$(date '+%H:%M:%S')] Preserving waiting_for_input state" >> ~/.claude/hook-debug.log
  fi
else
  # Default to idle if can't check state
  $DOTFILES_DIR/claude/scripts/state/update-session-state.sh idle
fi
