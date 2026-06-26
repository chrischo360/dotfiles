#!/bin/bash

# Shared agent notification hook for Claude, Pi, and Devin.
# Sends a macOS notification (terminal-notifier) when an agent finishes.
# Captures tmux context for a click-to-focus action.
#
# Usage: notify.sh [AGENT_LABEL]
#   AGENT_LABEL - shown in the title (e.g. "Claude", "Pi", "Devin"). Default: "Agent".

AGENT="${1:-Agent}"

# Check if terminal-notifier is installed
if ! command -v terminal-notifier &> /dev/null; then
    echo "terminal-notifier not found. Install with: brew install terminal-notifier"
    exit 0
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

TMUX_INFO=""
EXECUTE_CMD=""

# Capture tmux context if available
if [ -n "$TMUX" ]; then
    TMUX_INFO=$(tmux display-message -p '#S:#I.#P [#W]')

    TMUX_SESSION=$(tmux display-message -p '#S')
    TMUX_WINDOW=$(tmux display-message -p '#I')
    TMUX_PANE=$(tmux display-message -p '#P')

    EXECUTE_CMD="${SCRIPT_DIR}/notify-click-handler.sh ${TMUX_SESSION}:${TMUX_WINDOW}.${TMUX_PANE}"
fi

# Location: git repo name or current directory name
if git rev-parse --git-dir > /dev/null 2>&1; then
    LOCATION=$(basename "$(git rev-parse --show-toplevel)")
else
    LOCATION=$(basename "$PWD")
fi

NOTIFY_CMD=(
    terminal-notifier
    -title "🤖 ${AGENT} Complete"
    -message "Repository: $LOCATION"
    -sound "default"
)

[ -n "$TMUX_INFO" ] && NOTIFY_CMD+=(-subtitle "$TMUX_INFO")
[ -n "$EXECUTE_CMD" ] && NOTIFY_CMD+=(-execute "$EXECUTE_CMD")

"${NOTIFY_CMD[@]}"
