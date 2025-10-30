#!/bin/bash

# Handler script for notification clicks
# Called by terminal-notifier when user clicks the notification
# Usage: notify-click-handler.sh SESSION:WINDOW.PANE

TMUX_TARGET="${1}"

if [ -z "$TMUX_TARGET" ]; then
    exit 1
fi

# Activate Alacritty
osascript -e 'tell application "Alacritty" to activate' 2>/dev/null &

# Small delay to let window activate
sleep 0.3

# Parse the target
SESSION=$(echo "$TMUX_TARGET" | cut -d: -f1)
WINDOW_PANE=$(echo "$TMUX_TARGET" | cut -d: -f2)
WINDOW=$(echo "$WINDOW_PANE" | cut -d. -f1)
PANE=$(echo "$WINDOW_PANE" | cut -d. -f2)

FULL_TARGET="${SESSION}:${WINDOW}.${PANE}"

# Execute tmux commands
# The key is to use -t to target specific clients
tmux select-window -t "${SESSION}:${WINDOW}" 2>/dev/null
tmux select-pane -t "${FULL_TARGET}" 2>/dev/null

# If the above didn't work, try switching clients
# List all clients attached to this session and switch them
for client in $(tmux list-clients -t "${SESSION}" -F '#{client_name}' 2>/dev/null); do
    tmux switch-client -c "${client}" -t "${SESSION}:${WINDOW}" 2>/dev/null
    tmux select-pane -t "${FULL_TARGET}" 2>/dev/null
done
