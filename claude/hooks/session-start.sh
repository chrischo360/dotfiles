#!/bin/bash
# Hook: SessionStart - Called when Claude session starts
echo "[$(date '+%H:%M:%S')] SessionStart hook fired" >> ~/.claude/hook-debug.log
~/dotfiles/claude/scripts/update-session-state.sh start
