#!/bin/bash

# Handler script for notification clicks (terminal-notifier -execute).
# Raises the terminal app and focuses the tmux pane the agent ran in.
# Usage: notify-click-handler.sh SESSION:WINDOW.PANE [TERM_APP] [TMUX_BIN]

TMUX_TARGET="${1}"
TERM_APP="${2}"
TMUX_BIN="${3:-tmux}"   # absolute path passed by notify.sh (minimal PATH here)

if [ -z "$TMUX_TARGET" ]; then
    exit 1
fi

# Raise the terminal app that launched the agent (passed by notify.sh).
# If unknown, skip activation — the tmux pane focus below still applies.
if [ -n "$TERM_APP" ]; then
    osascript -e "tell application \"$TERM_APP\" to activate" 2>/dev/null &
    sleep 0.3
fi

# Parse the target
SESSION=$(echo "$TMUX_TARGET" | cut -d: -f1)
WINDOW_PANE=$(echo "$TMUX_TARGET" | cut -d: -f2)
WINDOW=$(echo "$WINDOW_PANE" | cut -d. -f1)
PANE=$(echo "$WINDOW_PANE" | cut -d. -f2)

FULL_TARGET="${SESSION}:${WINDOW}.${PANE}"

# Focus the right window/pane
"$TMUX_BIN" select-window -t "${SESSION}:${WINDOW}" 2>/dev/null
"$TMUX_BIN" select-pane -t "${FULL_TARGET}" 2>/dev/null

# If the above didn't switch the attached client, switch it explicitly
for client in $("$TMUX_BIN" list-clients -t "${SESSION}" -F '#{client_name}' 2>/dev/null); do
    "$TMUX_BIN" switch-client -c "${client}" -t "${SESSION}:${WINDOW}" 2>/dev/null
    "$TMUX_BIN" select-pane -t "${FULL_TARGET}" 2>/dev/null
done
