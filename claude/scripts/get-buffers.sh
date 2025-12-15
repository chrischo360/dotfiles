#!/usr/bin/env bash
# Fetch Neovim buffer tracking data for current project
# Returns JSON with all tracked buffers and importance scores

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

# Calculate importance score (matches nvim lua logic)
calculate_score() {
  local access=$1
  local saves=$2

  # Normalize to max 10, then apply weights
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

  # Find project hash from manifest
  local project_hash=""
  project_hash=$(jq -r --arg proj "$project_root" 'to_entries[] | select(.value == $proj) | .key' "$MANIFEST" | head -1)

  # If not found, return empty
  if [[ -z "$project_hash" ]]; then
    echo '{"error": "Project not tracked", "project": "'"$project_root"'", "available_projects": '$(jq -c 'to_entries | map(.value)' "$MANIFEST")'}'
    exit 0
  fi

  # Read buffer tracking file
  local tracking_file="$TRACKING_DIR/${project_hash}.json"
  if [[ ! -f "$tracking_file" ]]; then
    echo '{"error": "Tracking file not found", "project": "'"$project_root"'"}'
    exit 0
  fi

  # Build output JSON
  echo "{"
  echo "  \"project\": \"$(basename "$project_root")\","
  echo "  \"project_path\": \"$project_root\","
  echo "  \"buffers\": ["

  local first=true
  while IFS= read -r filepath; do
    local access=$(jq -r --arg fp "$filepath" '.[$fp].access // 0' "$tracking_file")
    local saves=$(jq -r --arg fp "$filepath" '.[$fp].saves // 0' "$tracking_file")
    local score=$(calculate_score "$access" "$saves")

    if [[ "$first" == true ]]; then
      first=false
    else
      echo ","
    fi

    echo -n "    {\"path\": \"$filepath\", \"access\": $access, \"saves\": $saves, \"score\": $score}"
  done < <(jq -r 'keys[]' "$tracking_file")

  echo ""
  echo "  ]"
  echo "}"
}

main "$@"
