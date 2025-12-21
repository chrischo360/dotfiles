#!/bin/bash
# Hook: User input submitted - Mark session as active
echo "[$(date '+%H:%M:%S')] UserPromptSubmit hook fired" >> ~/.claude/hook-debug.log
$DOTFILES_DIR/claude/scripts/update-session-state.sh active
