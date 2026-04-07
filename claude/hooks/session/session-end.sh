#!/bin/bash
# Hook: SessionEnd - Called when Claude session ends
$DOTFILES_DIR/claude/scripts/state/update-session-state.sh stop

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
PROJECT_NAME=$(basename "$PROJECT_DIR")
SAFE_PROJECT_NAME="${PROJECT_NAME//\//_}"
rm -f "/tmp/claude-context-warned-${SAFE_PROJECT_NAME}.txt"
