#!/bin/bash
# Display mpv status for tmux statusline
# Shows 🎵 Title [Time] when mpv is playing

# Check if mpv is running
if ! pgrep -x mpv > /dev/null 2>&1; then
  echo ""
  exit 0
fi

# Check if IPC socket exists
if [ ! -S /tmp/mpvsocket ]; then
  # Fallback to simple icon if no IPC
  echo " 🎵"
  exit 0
fi

# Query media title
title_response=$(echo '{ "command": ["get_property", "media-title"] }' | socat - /tmp/mpvsocket 2>/dev/null)
title=$(echo "$title_response" | jq -r '.data' 2>/dev/null)

# Query time remaining
time_response=$(echo '{ "command": ["get_property", "time-remaining"] }' | socat - /tmp/mpvsocket 2>/dev/null)
time_remaining=$(echo "$time_response" | jq -r '.data' 2>/dev/null)

# Fallback if queries fail
if [ -z "$title" ] || [ "$title" = "null" ]; then
  echo " 🎵"
  exit 0
fi

# Format time as MM:SS
if [ -n "$time_remaining" ] && [ "$time_remaining" != "null" ]; then
  minutes=$(printf "%.0f" "$(echo "$time_remaining / 60" | bc)")
  seconds=$(printf "%.0f" "$(echo "$time_remaining % 60" | bc)")
  time_str=$(printf "%d:%02d" "$minutes" "$seconds")
else
  time_str=""
fi

# Truncate title to 30 chars
if [ ${#title} -gt 30 ]; then
  title="${title:0:27}..."
fi

# Output format:  🎵 Title [Time]
if [ -n "$time_str" ]; then
  echo " 🎵 $title [$time_str]"
else
  echo " 🎵 $title"
fi
