#!/bin/bash
# Display Claude session status for tmux statusline
# Shows format: [C: session1📖✏️ session2❓ session3✅]
# Icons show what Claude is doing: 📖 reading, ✏️ editing, ⚙️ running, 🔍 searching, etc.
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

jq -r '.sessions | to_entries[] | "\(.value.status)|\(.value.action // "")|\(.value.context.tmux_session // "?")|\(.value.context.repo // "?")|\(.value.context_warning // "")"' "$STATE_FILE" 2>/dev/null | while IFS='|' read -r status action tmux_session repo ctx_warning; do
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

  echo "$priority|$status|$action|$display_name|$ctx_warning" >> "$temp_file"
done

# Group by display_name, show all statuses/actions for each session
# State transitions:
#   SessionStart → active (processing starts)
#   UserPromptSubmit → active (user sent input)
#   PreToolUse(tool) → active + action (Claude using specific tool)
#   PostToolUse(tool) → active (tool completed, back to thinking)
#   PreToolUse(AskUserQuestion) → waiting_for_input + asking
#   Stop → idle (Claude finished responding)
session_displays=()
for session_name in $(cut -d'|' -f4 "$temp_file" | sort -u); do
  # Get all entries for this session, sorted by priority (active first, then waiting, then idle)
  entries=$(grep "|$session_name$" "$temp_file" | sort -rn)

  # Build icon string with all statuses
  icons=""
  while IFS='|' read -r priority status action display_name ctx_warning; do
    # Determine icon based on status and action
    icon=""
    if [[ "$status" == "idle" ]]; then
      icon="✅"  # Ready: Claude finished, waiting for user input
    elif [[ "$status" == "waiting_for_input" ]] || [[ "$action" == "asking" ]]; then
      icon="❓"  # Question: Claude asked a question, needs user response
    elif [[ -n "$action" ]]; then
      # Tool-specific actions
      case "$action" in
        reading)
          icon="📖"  # Reading: Read, Glob
          ;;
        searching)
          icon="🔍"  # Searching: Grep
          ;;
        editing)
          icon="✏️"  # Editing: Edit, Write
          ;;
        running)
          icon="⚙️"  # Running: Bash
          ;;
        delegating)
          icon="🤖"  # Delegating: Task
          ;;
        fetching)
          icon="🌐"  # Fetching: WebFetch, WebSearch
          ;;
        *)
          icon="🔄"  # Generic active
          ;;
      esac
    else
      # Active but no specific action
      icon="🔄"  # Working: Claude is actively processing/responding
    fi

    icons="${icons}${icon}"

    if [[ -n "$ctx_warning" ]] && (( $(echo "$ctx_warning >= 80" | bc -l) )); then
      icons="${icons}⚠️"
    fi
  done <<< "$entries"

  # Add session with all its icons
  if [[ -n "$icons" ]]; then
    session_displays+=("${session_name}${icons}")
  fi
done

# Format output
if [[ ${#session_displays[@]} -eq 0 ]]; then
  echo ""
else
  # Join session displays with space
  output="C: ${session_displays[*]}"
  echo "$output"
fi
