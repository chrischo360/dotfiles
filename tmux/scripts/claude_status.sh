#!/bin/bash
# Display Claude session status for tmux statusline
# Shows format: [C: session1⚡ session2⏸️]
# Grouped by tmux session, auto-cleans dead panes

STATE_FILE="$HOME/.claude/session-state.json"

# Check if state file exists
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
    # Check if pane still exists
    if [[ ! "$active_panes" =~ "$pane_id" ]]; then
      # Remove dead pane
      jq --arg pane "$pane_id" 'del(.sessions[$pane])' "$STATE_FILE" > "$STATE_FILE.tmp" && mv "$STATE_FILE.tmp" "$STATE_FILE"
    fi
  done
fi

# Read and parse state file, create temp file for grouping
temp_file=$(mktemp)
trap 'rm -f "$temp_file"' EXIT

jq -r '.sessions | to_entries[] | "\(.value.status)|\(.value.context.tmux_session // "?")|\(.value.context.repo // "?")"' "$STATE_FILE" 2>/dev/null | while IFS='|' read -r status tmux_session repo; do
  # Use tmux session name, fallback to repo if not available
  display_name="$tmux_session"
  if [[ -z "$display_name" || "$display_name" == "?" || "$display_name" == "unknown" ]]; then
    display_name="$repo"
  fi
  if [[ -z "$display_name" || "$display_name" == "?" ]]; then
    display_name="unknown"
  fi

  # Priority: active=3, waiting_for_input=2, idle=1
  priority=1
  [[ "$status" == "waiting_for_input" ]] && priority=2
  [[ "$status" == "active" ]] && priority=3

  echo "$priority|$status|$display_name" >> "$temp_file"
done

# Group by display_name, keep highest priority status
session_displays=()
for session_name in $(cut -d'|' -f3 "$temp_file" | sort -u); do
  # Get highest priority status for this session
  status=$(grep "|$session_name$" "$temp_file" | sort -rn | head -1 | cut -d'|' -f2)

  # Add icon based on status
  case "$status" in
    active)
      session_displays+=("${session_name}⚡")
      ;;
    idle)
      session_displays+=("${session_name}⏸️")
      ;;
    waiting_for_input)
      session_displays+=("${session_name}⏳")
      ;;
  esac
done

# Format output
if [[ ${#session_displays[@]} -eq 0 ]]; then
  echo ""
else
  # Join session displays with space
  output="C: ${session_displays[*]}"
  echo "$output"
fi
