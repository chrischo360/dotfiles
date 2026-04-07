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

# Context rot warning: notify when context usage crosses 70%
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
PROJECT_NAME=$(basename "$PROJECT_DIR")
SAFE_PROJECT_NAME="${PROJECT_NAME//\//_}"
TOKEN_FILE="/tmp/claude-tokens-${SAFE_PROJECT_NAME}.txt"
WARNING_FILE="/tmp/claude-context-warned-${SAFE_PROJECT_NAME}.txt"

if [[ -f "$TOKEN_FILE" ]]; then
  PERCENTAGE=$(grep -o '([0-9.]*%)' "$TOKEN_FILE" | tr -d '()%' | head -1)
  THRESHOLD=80

  if [[ -n "$PERCENTAGE" ]] && (( $(echo "$PERCENTAGE >= $THRESHOLD" | bc -l) )); then
    LAST_WARNED=$(cat "$WARNING_FILE" 2>/dev/null || echo "0")
    if (( $(echo "$PERCENTAGE > $LAST_WARNED" | bc -l) )); then
      echo "$PERCENTAGE" > "$WARNING_FILE"
      terminal-notifier \
        -title "Claude: Context Warning" \
        -message "${PERCENTAGE}% context used — consider starting a new session" \
        -sound default \
        -group "claude-context-warning" 2>/dev/null || true

      if [[ -f "$STATE_FILE" && -n "$PANE_ID" ]]; then
        jq --arg pane "$PANE_ID" --arg pct "$PERCENTAGE" \
          '.sessions[$pane].context_warning = ($pct | tonumber)' \
          "$STATE_FILE" > "${STATE_FILE}.tmp" && mv "${STATE_FILE}.tmp" "$STATE_FILE"
      fi
    fi
  fi
fi
