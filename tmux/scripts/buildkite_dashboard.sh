#!/bin/bash
# Buildkite Dashboard - Display PR build status for monitored repositories
# Used by buildkite_monitor_loop.sh for continuous monitoring

set -euo pipefail

# Configuration
CACHE_FILE="${BUILDKITE_MONITOR_CACHE:-$HOME/.claude/buildkite-dashboard-cache.json}"
REPOS="${BUILDKITE_MONITOR_REPOS:-block-builder-api sf-js-libraries sf-ui-web sf-ui-cart-and-checkout}"

# Repo paths mapping
declare -A REPO_PATHS=(
  ["block-builder-api"]="$HOME/codebase/block-builder-api"
  ["sf-js-libraries"]="$HOME/codebase/sf-js-libraries"
  ["sf-ui-web"]="$HOME/codebase/sf-ui-web"
  ["sf-ui-cart-and-checkout"]="$HOME/codebase/sf-ui-cart-and-checkout"
)

# Time calculation function (from buildkite-monitor-pr.sh)
calculate_elapsed_time() {
  local start_time=$1
  local current_time=$(date +%s)
  local elapsed=$((current_time - start_time))

  local minutes=$((elapsed / 60))
  local seconds=$((elapsed % 60))

  if [[ $minutes -gt 0 ]]; then
    echo "${minutes}m ${seconds}s ago"
  else
    echo "${seconds}s ago"
  fi
}

# Get PR status for a repository
get_repo_status() {
  local repo_name=$1
  local repo_path=${REPO_PATHS[$repo_name]:-}

  if [[ -z "$repo_path" ]] || [[ ! -d "$repo_path/.git" ]]; then
    echo "NOT_FOUND"
    return 1
  fi

  cd "$repo_path" || return 1

  # Get PR info
  local pr_data
  if ! pr_data=$(gh pr view --json number,headRefName,statusCheckRollup 2>/dev/null); then
    echo "NO_PR"
    return 0
  fi

  local pr_number=$(echo "$pr_data" | jq -r '.number // empty')
  local branch=$(echo "$pr_data" | jq -r '.headRefName // empty')

  if [[ -z "$pr_number" ]]; then
    echo "NO_PR"
    return 0
  fi

  # Find Buildkite check
  local buildkite_check=$(echo "$pr_data" | jq -r '
    .statusCheckRollup[]? |
    select(.name | test("buildkite|Build")) |
    select(.conclusion != null or .status == "IN_PROGRESS" or .status == "PENDING")
  ' | head -n1)

  if [[ -z "$buildkite_check" ]]; then
    echo "NO_BUILDKITE"
    return 0
  fi

  local status=$(echo "$buildkite_check" | jq -r '.conclusion // .status')
  local check_name=$(echo "$buildkite_check" | jq -r '.name')
  local target_url=$(echo "$buildkite_check" | jq -r '.detailsUrl // empty')
  local updated_at=$(echo "$buildkite_check" | jq -r '.completedAt // .startedAt // empty')

  # Extract build number from URL
  local build_number=""
  if [[ -n "$target_url" ]]; then
    build_number=$(echo "$target_url" | grep -oE '[0-9]+$' || echo "")
  fi

  # Calculate elapsed time
  local elapsed="unknown"
  if [[ -n "$updated_at" ]]; then
    local timestamp=$(date -j -f "%Y-%m-%dT%H:%M:%SZ" "$updated_at" +%s 2>/dev/null || echo "")
    if [[ -n "$timestamp" ]]; then
      elapsed=$(calculate_elapsed_time "$timestamp")
    fi
  fi

  # Map GitHub status to readable format
  case "$status" in
    SUCCESS|COMPLETED) status="SUCCESS" ;;
    IN_PROGRESS|PENDING|QUEUED) status="RUNNING" ;;
    FAILURE|FAILED) status="FAILURE" ;;
    ERROR|CANCELLED) status="ERROR" ;;
    *) status="UNKNOWN" ;;
  esac

  # Create JSON output
  jq -n \
    --arg name "$repo_name" \
    --arg pr "$pr_number" \
    --arg branch "$branch" \
    --arg status "$status" \
    --arg build "$build_number" \
    --arg url "$target_url" \
    --arg elapsed "$elapsed" \
    --arg check_name "$check_name" \
    '{
      name: $name,
      pr_number: $pr,
      branch: $branch,
      status: $status,
      build_number: $build,
      build_url: $url,
      elapsed_time: $elapsed,
      check_name: $check_name
    }'
}

# Format dashboard output
format_dashboard() {
  local cache_data=$1
  local timestamp=$(date "+%H:%M:%S")

  echo "┌─ Buildkite Monitor ──────────────────────── Updated: $timestamp ─┐"
  echo "│                                                                  │"

  echo "$cache_data" | jq -r '.repos[] |
    if .status == "NO_PR" then
      "│ \(.name)\n│   No active PR\n│"
    elif .status == "NO_BUILDKITE" then
      "│ \(.name)\n│   PR #\(.pr_number) (\(.branch))\n│   No Buildkite check found\n│"
    elif .status == "NOT_FOUND" then
      "│ \(.name)\n│   Repository not found\n│"
    else
      "│ \(.name)\n│   PR #\(.pr_number) (\(.branch))\n│   " +
      (if .status == "SUCCESS" then "✓"
       elif .status == "RUNNING" then "⏳"
       elif .status == "FAILURE" then "✗"
       else "?" end) +
      " \(.status) - Build #\(.build_number) (\(.elapsed_time))\n│   \(.build_url)\n│"
    end
  '

  echo "└──────────────────────────────────────────────────────────────────┘"
}

# Main execution
main() {
  mkdir -p "$(dirname "$CACHE_FILE")"

  # Collect status for all repos
  local repo_statuses=()
  for repo in $REPOS; do
    local status_output=$(get_repo_status "$repo" 2>/dev/null || echo "")

    if [[ "$status_output" == "NO_PR" ]]; then
      repo_statuses+=($(jq -n --arg name "$repo" '{name: $name, status: "NO_PR"}'))
    elif [[ "$status_output" == "NO_BUILDKITE" ]]; then
      repo_statuses+=($(jq -n --arg name "$repo" '{name: $name, status: "NO_BUILDKITE"}'))
    elif [[ "$status_output" == "NOT_FOUND" ]]; then
      repo_statuses+=($(jq -n --arg name "$repo" '{name: $name, status: "NOT_FOUND"}'))
    elif [[ -n "$status_output" ]]; then
      repo_statuses+=("$status_output")
    fi
  done

  # Build cache JSON
  local cache_json=$(jq -n \
    --arg timestamp "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
    --argjson repos "$(printf '%s\n' "${repo_statuses[@]}" | jq -s '.')" \
    '{last_update: $timestamp, repos: $repos}'
  )

  # Write to cache
  echo "$cache_json" > "$CACHE_FILE"

  # Display dashboard
  format_dashboard "$cache_json"
}

main "$@"
