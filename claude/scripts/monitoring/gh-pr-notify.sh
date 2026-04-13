#!/bin/bash
# GitHub PR notification monitor
# Polls all open PRs for new review comments and CI/CD failures
# State persisted to avoid duplicate notifications
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
LOG_FILE="/tmp/gh-pr-notify.log"
POLL_INTERVAL=300
ONCE_MODE=false
DRY_RUN=false
STATUS_MODE=false

while [[ $# -gt 0 ]]; do
  case $1 in
    --once) ONCE_MODE=true; shift ;;
    --reset) rm -f "$STATE_FILE"; echo "State cleared."; shift ;;
    --dry-run) DRY_RUN=true; shift ;;
    --status) STATUS_MODE=true; shift ;;
    --interval) POLL_INTERVAL="$2"; shift 2 ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

mkdir -p "$STATE_DIR"

if [[ ! -f "$STATE_FILE" ]]; then
  echo '{"seen_comments":{},"seen_failures":{}}' > "$STATE_FILE"
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
  local category="$1" key="$2"
  jq -r --arg cat "$category" --arg key "$key" '.[$cat][$key] // ""' "$STATE_FILE"
}

mark_seen() {
  local category="$1" key="$2" value="$3"
  local tmp
  tmp=$(mktemp)
  jq --arg cat "$category" --arg key "$key" --arg val "$value" \
    '.[$cat][$key] = $val' "$STATE_FILE" > "$tmp" && mv "$tmp" "$STATE_FILE"
}

check_prs() {
  log "Checking PRs..."

  local prs
  prs=$(gh search prs --author=@me --state=open --json repository,number,title,url 2>/dev/null) || {
    log "ERROR: Failed to fetch PRs"
    return 1
  }

  local pr_count
  pr_count=$(echo "$prs" | jq 'length')
  log "Found $pr_count open PRs"

  if [[ "$pr_count" -eq 0 ]]; then
    return 0
  fi

  echo "$prs" | jq -c '.[]' | while read -r pr; do
    local repo number title url
    repo=$(echo "$pr" | jq -r '.repository.nameWithOwner')
    number=$(echo "$pr" | jq -r '.number')
    title=$(echo "$pr" | jq -r '.title')
    url=$(echo "$pr" | jq -r '.url')

    check_comments "$repo" "$number" "$title" "$url"
    check_ci "$repo" "$number" "$title" "$url"
  done
}

check_comments() {
  local repo="$1" number="$2" title="$3" url="$4"
  local state_key="${repo}#${number}"

  local comments
  comments=$(gh api "repos/${repo}/pulls/${number}/reviews" \
    --jq '[.[] | select(.state != "PENDING")] | sort_by(.submitted_at) | last | {id: .id, user: .user.login, state: .state, submitted_at: .submitted_at}' 2>/dev/null) || return 0

  local review_id
  review_id=$(echo "$comments" | jq -r '.id // ""')
  [[ -z "$review_id" || "$review_id" == "null" ]] && return 0

  local seen
  seen=$(get_seen "seen_comments" "$state_key")
  [[ "$seen" == "$review_id" ]] && return 0

  local reviewer state
  reviewer=$(echo "$comments" | jq -r '.user')
  state=$(echo "$comments" | jq -r '.state')

  local label
  case "$state" in
    APPROVED) label="approved" ;;
    CHANGES_REQUESTED) label="requested changes on" ;;
    COMMENTED) label="commented on" ;;
    DISMISSED) label="dismissed review on" ;;
    *) label="reviewed" ;;
  esac

  notify "PR Review: ${repo}#${number}" "${reviewer} ${label}: ${title}" "$url"
  mark_seen "seen_comments" "$state_key" "$review_id"
}

check_ci() {
  local repo="$1" number="$2" title="$3" url="$4"
  local state_key="${repo}#${number}"

  local status
  status=$(gh api "repos/${repo}/commits/$(gh api "repos/${repo}/pulls/${number}" --jq '.head.sha' 2>/dev/null)/check-runs" \
    --jq '{
      failed: [.check_runs[] | select(.conclusion == "failure" or .conclusion == "timed_out") | .name],
      sha: (.check_runs[0].head_sha // "")
    }' 2>/dev/null) || return 0

  local failed_count sha
  failed_count=$(echo "$status" | jq '.failed | length')
  sha=$(echo "$status" | jq -r '.sha')

  [[ "$failed_count" -eq 0 || -z "$sha" || "$sha" == "null" ]] && return 0

  local seen_sha
  seen_sha=$(get_seen "seen_failures" "$state_key")
  local failure_key="${sha}:${failed_count}"
  [[ "$seen_sha" == "$failure_key" ]] && return 0

  local failed_names
  failed_names=$(echo "$status" | jq -r '.failed | join(", ")' | head -c 100)

  notify "CI Failed: ${repo}#${number}" "${failed_names}" "$url"
  mark_seen "seen_failures" "$state_key" "$failure_key"
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

  # Column widths
  local col_pr=35 col_review=20 col_ci=30

  # Header
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

    # Fetch review status
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

    # Fetch CI status
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

    # Truncate PR label to fit column
    local pr_label="${repo}#${number}"
    if [[ ${#pr_label} -gt $col_pr ]]; then
      pr_label="${pr_label:0:$((col_pr - 2))}.."
    fi

    printf " %-${col_pr}s %-${col_review}s %s\n" "$pr_label" "$review_display" "$ci_display"
  done

  echo ""
}

cleanup_state() {
  local prs
  prs=$(gh search prs --author=@me --state=open --json repository,number 2>/dev/null) || return 0

  local active_keys
  active_keys=$(echo "$prs" | jq -r '.[] | "\(.repository.nameWithOwner)#\(.number)"')

  local tmp
  tmp=$(mktemp)
  jq --argjson keys "$(echo "$active_keys" | jq -R -s 'split("\n") | map(select(length > 0))')" '
    .seen_comments |= with_entries(select(.key as $k | $keys | any(. == $k))) |
    .seen_failures |= with_entries(select(.key as $k | $keys | any(. == $k)))
  ' "$STATE_FILE" > "$tmp" && mv "$tmp" "$STATE_FILE"
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
  check_prs
  cleanup_state
else
  while true; do
    check_prs || true
    cleanup_state || true
    sleep "$POLL_INTERVAL"
  done
fi
