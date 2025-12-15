#!/bin/bash
# Session start hook: Inject buffer tracking data into Claude's context
# Output to stderr so it displays in terminal before session starts

{
  echo "📊 Buffer Activity (Top 20 active files)"
  echo ""

  # Get and process buffer data
  BUFFER_DATA=$(~/dotfiles/claude/scripts/get-buffers.sh)

  # Extract and display high-score files (>= 0.6)
  echo "High-activity files (score >= 0.6):"
  echo "$BUFFER_DATA" | jq -r '.buffers[] | select(.score >= 0.6) | "  \(.score | tostring | .[0:4])  \(.path | split("/") | .[-1])"' | head -20
  echo ""

  # Output filtered JSON (score >= 0.3, top 20)
  echo "$BUFFER_DATA" | jq '{
  project: .project,
  project_path: .project_path,
  buffers: [.buffers[] | select(.score >= 0.3)] | sort_by(-.score) | .[0:20]
}'

  echo ""
  echo "Context: High scores indicate active editing. Use these files when exploring related code."
} >&2
