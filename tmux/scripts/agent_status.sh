#!/bin/bash
# Shared agent session status renderer for tmux.
# Usage: agent_status.sh <label> <state-file>

LABEL="$1"
STATE_FILE="$2"

if [[ -z "$LABEL" || -z "$STATE_FILE" || ! -f "$STATE_FILE" ]]; then
  echo ""
  exit 0
fi

active_panes=""
if [[ -n "$TMUX" ]]; then
  active_panes="|$(tmux list-panes -a -F '#{pane_id}' 2>/dev/null | tr '\n' '|')"
fi

if [[ -n "$active_panes" ]]; then
  for pane_id in $(jq -r '.sessions | keys[]' "$STATE_FILE" 2>/dev/null); do
    if [[ "$active_panes" != *"|$pane_id|"* ]]; then
      jq --arg pane "$pane_id" 'del(.sessions[$pane])' "$STATE_FILE" > "$STATE_FILE.tmp" && mv "$STATE_FILE.tmp" "$STATE_FILE"
    fi
  done
fi

temp_file=$(mktemp)
trap 'rm -f "$temp_file"' EXIT

jq -r '.sessions | to_entries[] | "\(.value.status // "")|\(.value.action // "")|\(.value.context.tmux_session // "?")|\(.value.context.repo // "?")|\(.value.context_warning // "")"' "$STATE_FILE" 2>/dev/null |
while IFS='|' read -r status action tmux_session repo ctx_warning; do
  display_name="$tmux_session"
  if [[ -z "$display_name" || "$display_name" == "?" || "$display_name" == "unknown" ]]; then
    display_name="$repo"
  fi
  if [[ -z "$display_name" || "$display_name" == "?" ]]; then
    display_name="unknown"
  fi

  priority=1
  [[ "$status" == "waiting_for_input" ]] && priority=2
  [[ "$status" == "active" ]] && priority=3

  echo "$priority|$status|$action|$display_name|$ctx_warning" >> "$temp_file"
done

state_badge() {
  local status="$1"
  local action="$2"
  local display_name="$3"
  local ctx_warning="$4"
  local style="#[fg=black,bg=yellow]"
  local label="work"

  if [[ "$status" == "idle" ]]; then
    style="#[fg=black,bg=green]"
    label="done"
  elif [[ "$status" == "waiting_for_input" || "$action" == "asking" ]]; then
    style="#[fg=white,bg=red]"
    label="wait"
  elif [[ "$status" == "active" ]]; then
    case "$action" in
      reading)
        style="#[fg=black,bg=cyan]"
        label="read"
        ;;
      searching)
        style="#[fg=white,bg=blue]"
        label="search"
        ;;
      editing)
        style="#[fg=white,bg=magenta]"
        label="edit"
        ;;
      running)
        style="#[fg=black,bg=yellow]"
        label="run"
        ;;
      delegating)
        style="#[fg=white,bg=blue]"
        label="agent"
        ;;
      fetching)
        style="#[fg=black,bg=cyan]"
        label="web"
        ;;
      *)
        style="#[fg=black,bg=yellow]"
        label="work"
        ;;
    esac
  fi

  if [[ -n "$ctx_warning" ]] && awk -v pct="$ctx_warning" 'BEGIN { exit !(pct >= 80) }'; then
    style="#[fg=white,bg=red]"
    label="ctx ${ctx_warning%.*}%"
  fi

  printf '%s %s #[default]' "$style" "$display_name"
}

session_displays=()
while IFS= read -r session_name; do
  [[ -z "$session_name" ]] && continue
  entries=$(awk -F'|' -v name="$session_name" '$4 == name' "$temp_file" | sort -rn)

  while IFS='|' read -r priority status action display_name ctx_warning; do
    [[ -z "$status" ]] && continue
    session_displays+=("$(state_badge "$status" "$action" "$display_name" "$ctx_warning")")
  done <<< "$entries"
done < <(cut -d'|' -f4 "$temp_file" 2>/dev/null | sort -u)

if [[ ${#session_displays[@]} -eq 0 ]]; then
  echo ""
else
  printf '%s' "${session_displays[@]}"
  echo
fi
