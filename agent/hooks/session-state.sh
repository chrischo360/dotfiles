#!/bin/bash
# Shared session state writer for agent tmux statuslines.
# Usage: session-state.sh <agent> <start|active|idle|waiting|stop> [action]

AGENT="${1:-Agent}"
STATE_ACTION="${2:-active}"
TOOL_ACTION="${3:-}"
AGENT_LC=$(printf '%s' "$AGENT" | tr '[:upper:]' '[:lower:]')

case "$AGENT_LC" in
  claude) STATE_FILE="$HOME/.claude/session-state.json" ;;
  pi)     STATE_FILE="$HOME/.pi/agent/session-state.json" ;;
  devin)  STATE_FILE="$HOME/.devin/session-state.json" ;;
  *)      STATE_FILE="$HOME/.$AGENT_LC/session-state.json" ;;
esac

get_context() {
  local dir="$(pwd)"
  local repo=""
  local branch=""

  if git rev-parse --git-dir >/dev/null 2>&1; then
    repo=$(basename "$(git rev-parse --show-toplevel)")
    branch=$(git branch --show-current 2>/dev/null || echo "")
  else
    repo=$(basename "$dir")
  fi

  local tmux_pane="$TMUX_PANE"
  local tmux_session_name="unknown"
  if [[ -n "$TMUX" ]]; then
    tmux_session_name=$(tmux display-message -p '#{session_name}' 2>/dev/null || echo "unknown")
  fi

  echo "$dir|$repo|$branch|$tmux_session_name|$tmux_pane"
}

init_state_file() {
  if [[ ! -f "$STATE_FILE" ]] || [[ ! -s "$STATE_FILE" ]] || ! jq empty "$STATE_FILE" 2>/dev/null; then
    mkdir -p "$(dirname "$STATE_FILE")"
    echo '{"sessions":{}}' > "$STATE_FILE"
  fi
}

update_state() {
  local action="$1"
  local pane_id="$TMUX_PANE"
  [[ -z "$pane_id" ]] && exit 0

  init_state_file

  local context timestamp
  context=$(get_context)
  IFS='|' read -r dir repo branch tmux_session_name tmux_pane <<< "$context"
  timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  case "$action" in
    start|active)
      if [[ -n "$TOOL_ACTION" ]]; then
        jq --arg pane "$pane_id" \
          --arg status "active" \
          --arg tool "$TOOL_ACTION" \
          --arg dir "$dir" \
          --arg repo "$repo" \
          --arg branch "$branch" \
          --arg session "$tmux_session_name" \
          --arg time "$timestamp" \
          '.sessions[$pane] = {
            status: $status,
            action: $tool,
            context: {
              dir: $dir,
              repo: $repo,
              branch: $branch,
              tmux_session: $session,
              tmux_pane: $pane
            },
            last_update: $time
          }' "$STATE_FILE" > "$STATE_FILE.tmp" && mv "$STATE_FILE.tmp" "$STATE_FILE"
      else
        jq --arg pane "$pane_id" \
          --arg status "active" \
          --arg dir "$dir" \
          --arg repo "$repo" \
          --arg branch "$branch" \
          --arg session "$tmux_session_name" \
          --arg time "$timestamp" \
          '.sessions[$pane] = {
            status: $status,
            context: {
              dir: $dir,
              repo: $repo,
              branch: $branch,
              tmux_session: $session,
              tmux_pane: $pane
            },
            last_update: $time
          }' "$STATE_FILE" > "$STATE_FILE.tmp" && mv "$STATE_FILE.tmp" "$STATE_FILE"
      fi
      ;;
    idle)
      jq --arg pane "$pane_id" \
        --arg status "idle" \
        --arg dir "$dir" \
        --arg repo "$repo" \
        --arg branch "$branch" \
        --arg session "$tmux_session_name" \
        --arg time "$timestamp" \
        '.sessions[$pane] = ((.sessions[$pane] // {
          context: {
            dir: $dir,
            repo: $repo,
            branch: $branch,
            tmux_session: $session,
            tmux_pane: $pane
          }
        }) |
        .status = $status |
        .last_update = $time |
        del(.action))' \
        "$STATE_FILE" > "$STATE_FILE.tmp" && mv "$STATE_FILE.tmp" "$STATE_FILE"
      ;;
    waiting)
      jq --arg pane "$pane_id" \
        --arg status "waiting_for_input" \
        --arg dir "$dir" \
        --arg repo "$repo" \
        --arg branch "$branch" \
        --arg session "$tmux_session_name" \
        --arg time "$timestamp" \
        '.sessions[$pane] = ((.sessions[$pane] // {
          context: {
            dir: $dir,
            repo: $repo,
            branch: $branch,
            tmux_session: $session,
            tmux_pane: $pane
          }
        }) |
        .status = $status |
        .action = "asking" |
        .last_update = $time)' \
        "$STATE_FILE" > "$STATE_FILE.tmp" && mv "$STATE_FILE.tmp" "$STATE_FILE"
      ;;
    stop)
      jq --arg pane "$pane_id" 'del(.sessions[$pane])' \
        "$STATE_FILE" > "$STATE_FILE.tmp" && mv "$STATE_FILE.tmp" "$STATE_FILE"
      ;;
  esac
}

update_state "$STATE_ACTION"
