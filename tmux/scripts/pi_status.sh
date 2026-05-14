#!/bin/bash
# Display Pi session status for tmux statusline
# Shows format: [Pi: session1📖 session2✏️ session3✅]
# Mirrors claude_status.sh but reads ~/.pi/agent/session-state.json

STATE_FILE="$HOME/.pi/agent/session-state.json"

if [[ ! -f "$STATE_FILE" ]]; then
  echo ""
  exit 0
fi

# Get list of active tmux panes
active_panes=""
if [[ -n "$TMUX" ]]; then
  active_panes=$(tmux list-panes -a -F '#{pane_id}' 2>/dev/null | tr '\n' '|')
fi

# Clean up dead panes from state file
if [[ -n "$active_panes" ]]; then
  for pane_id in $(jq -r '.sessions | keys[]' "$STATE_FILE" 2>/dev/null); do
    if [[ ! "$active_panes" =~ "$pane_id" ]]; then
      jq --arg pane "$pane_id" 'del(.sessions[$pane])' "$STATE_FILE" > "$STATE_FILE.tmp" && mv "$STATE_FILE.tmp" "$STATE_FILE"
    fi
  done
fi

temp_file=$(mktemp)
trap 'rm -f "$temp_file"' EXIT

# select(.value.context != null) skips old-format entries without context
jq -r '.sessions | to_entries[] | select(.value.context != null) | "\(.value.status)|\(.value.action // "")|\(.value.context.tmux_session // "?")|\(.value.context.repo // "?")"' "$STATE_FILE" 2>/dev/null | while IFS='|' read -r status action tmux_session repo; do
  display_name="$tmux_session"
  if [[ -z "$display_name" || "$display_name" == "?" || "$display_name" == "unknown" ]]; then
    display_name="$repo"
  fi
  if [[ -z "$display_name" || "$display_name" == "?" ]]; then
    display_name="unknown"
  fi

  priority=1
  [[ "$status" == "active" ]] && priority=2

  echo "$priority|$status|$action|$display_name" >> "$temp_file"
done

session_displays=()
for session_name in $(cut -d'|' -f4 "$temp_file" 2>/dev/null | sort -u); do
  entries=$(grep "|${session_name}$" "$temp_file" | sort -rn)

  icons=""
  while IFS='|' read -r priority status action display_name; do
    icon=""
    if [[ "$status" == "idle" ]]; then
      icon="✅"
    elif [[ -n "$action" ]]; then
      case "$action" in
        reading)   icon="📖" ;;
        searching) icon="🔍" ;;
        editing)   icon="✏️" ;;
        running)   icon="⚙️" ;;
        *)         icon="⚡" ;;
      esac
    else
      icon="⚡"
    fi
    icons="${icons}${icon}"
  done <<< "$entries"

  if [[ -n "$icons" ]]; then
    session_displays+=("${session_name}${icons}")
  fi
done

if [[ ${#session_displays[@]} -eq 0 ]]; then
  echo ""
else
  echo "Pi: ${session_displays[*]}"
fi
