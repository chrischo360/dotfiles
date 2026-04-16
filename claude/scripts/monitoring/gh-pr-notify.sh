#!/bin/bash
# GitHub PR notification monitor
# Uses GitHub Notifications API for efficient polling (1 API call per check)
# Supports conditional requests (If-Modified-Since) to avoid rate limit usage
# when nothing has changed.
#
# Usage:
#   gh-pr-notify.sh [--once] [--reset] [--dry-run] [--status] [--interval <seconds>]
#
# Options:
#   --once       Run once and exit (default: loop forever)
#   --reset      Clear saved state and start fresh
#   --dry-run    Show what would notify without sending
#   --status     Show formatted table of all tracked PRs
#   --interval   Poll interval in seconds (default: 300)

set -euo pipefail

STATE_DIR="$HOME/.cache/gh-pr-notify"
STATE_FILE="$STATE_DIR/state.json"
LAST_MODIFIED_FILE="$STATE_DIR/last-modified"
LOG_FILE="/tmp/gh-pr-notify.log"
POLL_INTERVAL=300
ONCE_MODE=false
DRY_RUN=false
STATUS_MODE=false

while [[ $# -gt 0 ]]; do
  case $1 in
    --once) ONCE_MODE=true; shift ;;
    --reset) rm -f "$STATE_FILE" "$LAST_MODIFIED_FILE"; echo "State cleared."; shift ;;
    --dry-run) DRY_RUN=true; shift ;;
    --status) STATUS_MODE=true; shift ;;
    --interval) POLL_INTERVAL="$2"; shift 2 ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

mkdir -p "$STATE_DIR"

if [[ ! -f "$STATE_FILE" ]]; then
  echo '{"seen":{}}' > "$STATE_FILE"
fi

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$LOG_FILE"
}

notify() {
  local title="$1"
  local message="$2"
  local url="${3:-}"

  if [[ "$DRY_RUN" == "true" ]]; then
    echo "[DRY RUN] $title: $message"
    log "[DRY RUN] $title: $message"
    return
  fi

  local cmd=(terminal-notifier -title "$title" -message "$message" -sound "default" -group "gh-pr-notify")
  if [[ -n "$url" ]]; then
    cmd+=(-open "$url")
  fi
  "${cmd[@]}" 2>/dev/null || true
  log "NOTIFY: $title - $message"
}

get_seen() {
  local key="$1"
  jq -r --arg key "$key" '.seen[$key] // ""' "$STATE_FILE"
}

mark_seen() {
  local key="$1" value="$2"
  local tmp
  tmp=$(mktemp)
  jq --arg key "$key" --arg val "$value" \
    '.seen[$key] = $val' "$STATE_FILE" > "$tmp" && mv "$tmp" "$STATE_FILE"
}

check_notifications() {
  log "Checking notifications..."

  local headers_file
  headers_file=$(mktemp)

  # Build curl args for conditional request
  local api_args=(
    "notifications"
    "--jq" '.'
    "-i"
  )

  # Use If-Modified-Since if we have a cached timestamp
  if [[ -f "$LAST_MODIFIED_FILE" ]]; then
    local last_mod
    last_mod=$(cat "$LAST_MODIFIED_FILE")
    api_args+=("-H" "If-Modified-Since: ${last_mod}")
  fi

  local response
  response=$(gh api "${api_args[@]}" 2>/dev/null) || {
    log "ERROR: Failed to fetch notifications"
    rm -f "$headers_file"
    return 1
  }
  rm -f "$headers_file"

  # Parse headers and body from -i output
  local headers body
  # Split on the blank line between headers and body
  headers=$(echo "$response" | sed '/^\r\{0,1\}$/q')
  body=$(echo "$response" | sed '1,/^\r\{0,1\}$/d')

  # Check for 304 Not Modified
  if echo "$headers" | grep -q "304"; then
    log "No changes (304 Not Modified)"
    return 0
  fi

  # Save Last-Modified header for next request
  local new_last_modified
  new_last_modified=$(echo "$headers" | grep -i "^Last-Modified:" | sed 's/^[^:]*: //' | tr -d '\r')
  if [[ -n "$new_last_modified" ]]; then
    echo "$new_last_modified" > "$LAST_MODIFIED_FILE"
  fi

  # Filter to only PullRequest notifications for reviews and CI
  local pr_notifications
  pr_notifications=$(echo "$body" | jq -c '[
    .[] | select(
      .subject.type == "PullRequest" and
      (.reason == "review_requested" or .reason == "comment" or .reason == "ci_activity" or .reason == "state_change" or .reason == "mention")
    )
  ]' 2>/dev/null) || {
    log "ERROR: Failed to parse notifications"
    return 1
  }

  local count
  count=$(echo "$pr_notifications" | jq 'length')
  log "Found $count relevant PR notifications"

  if [[ "$count" -eq 0 ]]; then
    return 0
  fi

  echo "$pr_notifications" | jq -c '.[]' | while read -r notif; do
    local notif_id updated_at reason subject_title subject_url repo_name
    notif_id=$(echo "$notif" | jq -r '.id')
    updated_at=$(echo "$notif" | jq -r '.updated_at')
    reason=$(echo "$notif" | jq -r '.reason')
    subject_title=$(echo "$notif" | jq -r '.subject.title')
    subject_url=$(echo "$notif" | jq -r '.subject.url')
    repo_name=$(echo "$notif" | jq -r '.repository.full_name')

    # Deduplicate using notif_id + updated_at
    local seen_key="${notif_id}"
    local seen_val
    seen_val=$(get_seen "$seen_key")
    [[ "$seen_val" == "$updated_at" ]] && continue

    # Convert API URL to web URL
    # subject.url is like: https://api.github.com/repos/owner/repo/pulls/123
    local pr_number web_url
    pr_number=$(echo "$subject_url" | grep -oE '[0-9]+$')
    web_url="https://github.com/${repo_name}/pull/${pr_number}"

    local title message
    case "$reason" in
      review_requested)
        title="Review Requested"
        message="${repo_name}#${pr_number}: ${subject_title}"
        ;;
      comment)
        title="PR Comment"
        message="${repo_name}#${pr_number}: ${subject_title}"
        ;;
      ci_activity)
        title="CI Update"
        message="${repo_name}#${pr_number}: ${subject_title}"
        ;;
      state_change)
        title="PR State Change"
        message="${repo_name}#${pr_number}: ${subject_title}"
        ;;
      mention)
        title="PR Mention"
        message="${repo_name}#${pr_number}: ${subject_title}"
        ;;
      *)
        title="PR Update"
        message="${repo_name}#${pr_number}: ${subject_title}"
        ;;
    esac

    notify "$title" "$message" "$web_url"
    mark_seen "$seen_key" "$updated_at"
  done
}

show_status() {
  local prs
  prs=$(gh search prs --author=@me --state=open --json repository,number,title,url 2>/dev/null) || {
    echo "Failed to fetch PRs"
    return 1
  }

  local pr_count
  pr_count=$(echo "$prs" | jq 'length')

  if [[ "$pr_count" -eq 0 ]]; then
    echo "No open PRs found."
    return 0
  fi

  local col_pr=35 col_review=20 col_ci=30

  printf "\n %-${col_pr}s %-${col_review}s %s\n" "PR" "Review" "CI"
  printf " %s %s %s\n" \
    "$(printf '─%.0s' $(seq 1 $col_pr))" \
    "$(printf '─%.0s' $(seq 1 $col_review))" \
    "$(printf '─%.0s' $(seq 1 $col_ci))"

  echo "$prs" | jq -c '.[]' | while read -r pr; do
    local repo number title url
    repo=$(echo "$pr" | jq -r '.repository.nameWithOwner')
    number=$(echo "$pr" | jq -r '.number')
    title=$(echo "$pr" | jq -r '.title')
    url=$(echo "$pr" | jq -r '.url')

    local review_display="--"
    local review_data
    review_data=$(gh api "repos/${repo}/pulls/${number}/reviews" \
      --jq '[.[] | select(.state != "PENDING")] | sort_by(.submitted_at) | last | {user: .user.login, state: .state}' 2>/dev/null) || true

    if [[ -n "$review_data" ]]; then
      local reviewer review_state
      reviewer=$(echo "$review_data" | jq -r '.user // ""')
      review_state=$(echo "$review_data" | jq -r '.state // ""')

      if [[ -n "$reviewer" && "$reviewer" != "null" ]]; then
        case "$review_state" in
          APPROVED)          review_display="approved ($reviewer)" ;;
          CHANGES_REQUESTED) review_display="changes ($reviewer)" ;;
          COMMENTED)         review_display="comment ($reviewer)" ;;
          DISMISSED)         review_display="dismissed ($reviewer)" ;;
          *)                 review_display="$review_state ($reviewer)" ;;
        esac
      fi
    fi

    local ci_display="--"
    local head_sha
    head_sha=$(gh api "repos/${repo}/pulls/${number}" --jq '.head.sha' 2>/dev/null) || true

    if [[ -n "$head_sha" && "$head_sha" != "null" ]]; then
      local check_data
      check_data=$(gh api "repos/${repo}/commits/${head_sha}/check-runs" \
        --jq '{
          total: .total_count,
          passed: [.check_runs[] | select(.conclusion == "success")] | length,
          failed: [.check_runs[] | select(.conclusion == "failure" or .conclusion == "timed_out")] | length,
          pending: [.check_runs[] | select(.status == "in_progress" or .status == "queued")] | length,
          failed_names: [.check_runs[] | select(.conclusion == "failure" or .conclusion == "timed_out") | .name] | join(", ")
        }' 2>/dev/null) || true

      if [[ -n "$check_data" ]]; then
        local total passed failed pending failed_names
        total=$(echo "$check_data" | jq -r '.total')
        passed=$(echo "$check_data" | jq -r '.passed')
        failed=$(echo "$check_data" | jq -r '.failed')
        pending=$(echo "$check_data" | jq -r '.pending')
        failed_names=$(echo "$check_data" | jq -r '.failed_names')

        if [[ "$failed" -gt 0 ]]; then
          ci_display="FAILED: ${failed_names:0:40}"
        elif [[ "$pending" -gt 0 ]]; then
          ci_display="pending (${passed}/${total} done)"
        elif [[ "$total" -gt 0 ]]; then
          ci_display="passing (${passed}/${total})"
        fi
      fi
    fi

    local pr_label="${repo}#${number}"
    if [[ ${#pr_label} -gt $col_pr ]]; then
      pr_label="${pr_label:0:$((col_pr - 2))}.."
    fi

    printf " %-${col_pr}s %-${col_review}s %s\n" "$pr_label" "$review_display" "$ci_display"
  done

  echo ""
}

if ! command -v terminal-notifier &>/dev/null; then
  echo "terminal-notifier not found. Install with: brew install terminal-notifier"
  exit 1
fi

if ! command -v gh &>/dev/null; then
  echo "gh CLI not found. Install with: brew install gh"
  exit 1
fi

if ! gh auth status &>/dev/null; then
  echo "gh CLI not authenticated. Run: gh auth login"
  exit 1
fi

if [[ "$STATUS_MODE" == "true" ]]; then
  show_status
  exit 0
fi

log "Starting gh-pr-notify (interval: ${POLL_INTERVAL}s, once: ${ONCE_MODE})"

if [[ "$ONCE_MODE" == "true" ]]; then
  check_notifications
else
  while true; do
    check_notifications || true
    sleep "$POLL_INTERVAL"
  done
fi
