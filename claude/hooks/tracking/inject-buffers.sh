#!/bin/bash
# Session start hook: Inject buffer tracking data into Claude's context
# Output to stderr so it displays in terminal before session starts

{
  echo "📊 Buffer Activity (Top 20 active files)"
  echo ""

  # Get and process buffer data
  BUFFER_DATA=$($DOTFILES_DIR/claude/scripts/utils/get-buffers.sh)

  # Check for errors
  if echo "$BUFFER_DATA" | jq -e '.error' >/dev/null 2>&1; then
    echo "⚠️  $(echo "$BUFFER_DATA" | jq -r '.error')"
    exit 0
  fi

  # Extract branch info
  branch=$(echo "$BUFFER_DATA" | jq -r '.branch // "unknown"')
  main_branch=$(echo "$BUFFER_DATA" | jq -r '.main_branch // "main"')

  echo "Branch: $branch"
  if [[ "$branch" != "$main_branch" ]]; then
    echo "(Includes high-activity files from $main_branch)"
  fi
  echo ""

  # Extract and display high-score files (>= 0.6)
  echo "High-activity files (score >= 0.6):"
  echo "$BUFFER_DATA" | jq -r '.buffers[] | select(.score >= 0.6) |
    if .from_main then
      "  \(.score | tostring | .[0:4])  \(.path | split("/") | .[-1]) (from main)"
    else
      "  \(.score | tostring | .[0:4])  \(.path | split("/") | .[-1])"
    end' | head -20
  echo ""

  # Output filtered JSON (score >= 0.3, top 20)
  echo "$BUFFER_DATA" | jq '{
    project: .project,
    project_path: .project_path,
    branch: .branch,
    main_branch: .main_branch,
    buffers: [.buffers[] | select(.score >= 0.3)] | sort_by(-.score) | .[0:20]
  }'

  echo ""
  echo "Context: High scores indicate active editing. Files marked 'from main' are high-importance files from $main_branch branch."
} >&2
