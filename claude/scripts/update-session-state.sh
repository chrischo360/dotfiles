#!/bin/bash
# Core script to manage Claude session state tracking
# Usage: update-session-state.sh <action>
# Actions: start, active, idle, waiting, stop

ACTION="$1"
STATE_FILE="$HOME/.claude/session-state.json"

# Get session context
get_context() {
  local dir="$(pwd)"
  local repo=""
  local branch=""

  # Try to get git info
  if git rev-parse --git-dir > /dev/null 2>&1; then
    repo=$(basename "$(git rev-parse --show-toplevel)")
    branch=$(git branch --show-current 2>/dev/null || echo "")
  fi

  # Get tmux info
  local tmux_pane="$TMUX_PANE"
  local tmux_session_name=""
  if [[ -n "$TMUX" ]]; then
    tmux_session_name=$(tmux display-message -p '#{session_name}' 2>/dev/null || echo "unknown")
  else
    tmux_session_name="unknown"
  fi

  echo "$dir|$repo|$branch|$tmux_session_name|$tmux_pane"
}

# Initialize state file if it doesn't exist
init_state_file() {
  if [[ ! -f "$STATE_FILE" ]]; then
    mkdir -p "$(dirname "$STATE_FILE")"
    echo '{"sessions":{}}' > "$STATE_FILE"
  fi
}

# Update session state
update_state() {
  local action="$1"
  local pane_id="$TMUX_PANE"

  [[ -z "$pane_id" ]] && exit 0  # Not in tmux, nothing to do

  init_state_file

  local context=$(get_context)
  IFS='|' read -r dir repo branch tmux_session_name tmux_pane <<< "$context"
  local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  case "$action" in
    start|active)
      # Add or update session with 'active' status
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
      ;;

    idle)
      # Mark session as idle
      jq --arg pane "$pane_id" \
         --arg status "idle" \
         --arg time "$timestamp" \
         '.sessions[$pane].status = $status |
          .sessions[$pane].last_update = $time' \
         "$STATE_FILE" > "$STATE_FILE.tmp" && mv "$STATE_FILE.tmp" "$STATE_FILE"
      ;;

    waiting)
      # Mark session as waiting for input
      jq --arg pane "$pane_id" \
         --arg status "waiting_for_input" \
         --arg time "$timestamp" \
         '.sessions[$pane].status = $status |
          .sessions[$pane].last_update = $time' \
         "$STATE_FILE" > "$STATE_FILE.tmp" && mv "$STATE_FILE.tmp" "$STATE_FILE"
      ;;

    stop)
      # Remove session from state
      jq --arg pane "$pane_id" \
         'del(.sessions[$pane])' \
         "$STATE_FILE" > "$STATE_FILE.tmp" && mv "$STATE_FILE.tmp" "$STATE_FILE"
      ;;
  esac
}

update_state "$ACTION"
