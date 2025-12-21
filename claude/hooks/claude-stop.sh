#!/bin/bash
# Hook: Stop - Called when Claude finishes responding
# Check if last message contains AskUserQuestion to determine state

# For now, default to idle (we can enhance this later to detect questions)
~/dotfiles/claude/scripts/update-session-state.sh idle

# TODO: Parse Claude's last output to detect if waiting for user input
# If AskUserQuestion was used, call:
# ~/dotfiles/claude/scripts/update-session-state.sh waiting
