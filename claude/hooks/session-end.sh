#!/bin/bash
# Hook: SessionEnd - Called when Claude session ends
$DOTFILES_DIR/claude/scripts/update-session-state.sh stop
