#!/usr/bin/env bash
# Fetch Neovim buffer tracking data for current project + branch
# Returns JSON with merged data (branch + high-importance main files)

set -euo pipefail

TRACKING_DIR="$HOME/.local/share/nvim/buffer_tracking"
MANIFEST="$TRACKING_DIR/manifest.json"

# Detect project root
detect_project_root() {
  if git rev-parse --show-toplevel 2>/dev/null; then
    return 0
  fi
  pwd
}

# Detect git branch
detect_git_branch() {
  if ! git rev-parse --git-dir >/dev/null 2>&1; then
    echo ""
    return
  fi

  # Try symbolic ref
  local branch
  branch=$(git symbolic-ref --short HEAD 2>/dev/null)
  if [[ -n "$branch" ]]; then
    echo "$branch"
    return
  fi

  # Detached HEAD
  local sha
  sha=$(git rev-parse --short HEAD 2>/dev/null)
  if [[ -n "$sha" ]]; then
    echo "detached-$sha"
  fi
}

# Detect main branch for project
detect_main_branch() {
  local project_root=$1

  # Try git config
  local default_branch
  default_branch=$(git -C "$project_root" config --get init.defaultBranch 2>/dev/null)
  if [[ -n "$default_branch" ]]; then
    echo "$default_branch"
    return
  fi

  # Try remote HEAD
  default_branch=$(git -C "$project_root" symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@')
  if [[ -n "$default_branch" ]]; then
    echo "$default_branch"
    return
  fi

  # Heuristic
  if git -C "$project_root" show-ref --verify --quiet refs/heads/main 2>/dev/null; then
    echo "main"
  elif git -C "$project_root" show-ref --verify --quiet refs/heads/master 2>/dev/null; then
    echo "master"
  else
    echo "main"
  fi
}

# Calculate importance score
calculate_score() {
  local access=$1
  local saves=$2

  local norm_access=$(echo "scale=2; if ($access > 10) 1 else $access / 10" | bc)
  local norm_saves=$(echo "scale=2; if ($saves > 10) 1 else $saves / 10" | bc)

  echo "scale=2; ($norm_access * 0.6) + ($norm_saves * 0.4)" | bc
}

# Main logic
main() {
  local project_root
  project_root=$(detect_project_root)

  # Check if manifest exists
  if [[ ! -f "$MANIFEST" ]]; then
    echo '{"error": "No buffer tracking data found", "project": "'"$project_root"'"}'
    exit 0
  fi

  # Find project hash from manifest (handle both old and new formats)
  local project_hash=""
  project_hash=$(jq -r --arg proj "$project_root" '
    to_entries[] |
    select(
      (.value == $proj) or
      (.value.project_root == $proj)
    ) | .key
  ' "$MANIFEST" | head -1)

  if [[ -z "$project_hash" ]]; then
    echo '{"error": "Project not tracked", "project": "'"$project_root"'"}'
    exit 0
  fi

  # Detect branch
  local branch
  branch=$(detect_git_branch)
  local main_branch
  main_branch=$(detect_main_branch "$project_root")

  # Use main branch if not in git repo
  if [[ -z "$branch" ]]; then
    branch="$main_branch"
  fi

  # Get project directory (new structure)
  local project_dir="$TRACKING_DIR/$project_hash"

  # Check for old format (single file) and suggest migration
  local old_file="$TRACKING_DIR/${project_hash}.json"
  if [[ -f "$old_file" ]] && [[ ! -d "$project_dir" ]]; then
    echo '{"error": "Old format detected. Please open neovim to migrate.", "project": "'"$project_root"'"}'
    exit 0
  fi

  local branch_file="$project_dir/${branch}.json"
  local main_file="$project_dir/${main_branch}.json"

  # Check if branch file exists
  if [[ ! -f "$branch_file" ]]; then
    echo '{"error": "Branch not tracked yet", "project": "'"$project_root"'", "branch": "'"$branch"'"}'
    exit 0
  fi

  # Build merged data
  local merged_data="{}"

  # Load branch data
  merged_data=$(jq -c '.' "$branch_file")

  # If not on main branch, merge high-importance files from main
  if [[ "$branch" != "$main_branch" ]] && [[ -f "$main_file" ]]; then
    # Get all filepaths from main with score >= 0.5
    while IFS= read -r filepath; do
      local access=$(jq -r --arg fp "$filepath" '.[$fp].access // 0' "$main_file")
      local saves=$(jq -r --arg fp "$filepath" '.[$fp].saves // 0' "$main_file")
      local score=$(calculate_score "$access" "$saves")

      # Only merge if score is high and not already in branch data
      if (( $(echo "$score >= 0.5" | bc -l) )); then
        local in_branch=$(echo "$merged_data" | jq --arg fp "$filepath" 'has($fp)')
        if [[ "$in_branch" == "false" ]]; then
          merged_data=$(echo "$merged_data" | jq \
            --arg fp "$filepath" \
            --argjson acc "$access" \
            --argjson sav "$saves" \
            '.[$fp] = {access: $acc, saves: $sav, from_main: true}')
        fi
      fi
    done < <(jq -r 'keys[]' "$main_file" 2>/dev/null || echo "")
  fi

  # Build output JSON
  echo "{"
  echo "  \"project\": \"$(basename "$project_root")\","
  echo "  \"project_path\": \"$project_root\","
  echo "  \"branch\": \"$branch\","
  echo "  \"main_branch\": \"$main_branch\","
  echo "  \"buffers\": ["

  local first=true
  while IFS= read -r filepath; do
    local access=$(echo "$merged_data" | jq -r --arg fp "$filepath" '.[$fp].access // 0')
    local saves=$(echo "$merged_data" | jq -r --arg fp "$filepath" '.[$fp].saves // 0')
    local from_main=$(echo "$merged_data" | jq -r --arg fp "$filepath" '.[$fp].from_main // false')
    local score=$(calculate_score "$access" "$saves")

    if [[ "$first" == true ]]; then
      first=false
    else
      echo ","
    fi

    echo -n "    {\"path\": \"$filepath\", \"access\": $access, \"saves\": $saves, \"score\": $score, \"from_main\": $from_main}"
  done < <(echo "$merged_data" | jq -r 'keys[]')

  echo ""
  echo "  ]"
  echo "}"
}

main "$@"
