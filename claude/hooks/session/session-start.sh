#!/bin/bash
# Hook: SessionStart - Called when Claude session starts
echo "[$(date '+%H:%M:%S')] SessionStart hook fired" >> ~/.claude/hook-debug.log
$DOTFILES_DIR/claude/scripts/state/update-session-state.sh start
