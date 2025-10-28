#!/bin/bash

# Claude Code notification script using terminal-notifier
# Captures tmux context and sends macOS notifications

EVENT_TYPE="${1:-Complete}"

# Check if terminal-notifier is installed
if ! command -v terminal-notifier &> /dev/null; then
    echo "terminal-notifier not found. Install with: brew install terminal-notifier"
    exit 1
fi

# Initialize variables
TMUX_INFO=""
LOCATION=""
EXECUTE_CMD=""

# Capture tmux context if available
if [ -n "$TMUX" ]; then
    # Get tmux session:window.pane and window name
    TMUX_INFO=$(tmux display-message -p '#S:#I.#P [#W]')

    # Capture current tmux target for the click action
    TMUX_SESSION=$(tmux display-message -p '#S')
    TMUX_WINDOW=$(tmux display-message -p '#I')
    TMUX_PANE=$(tmux display-message -p '#P')

    # Build execute command to activate Alacritty and switch to this pane
    EXECUTE_CMD="osascript -e 'tell application \"Alacritty\" to activate' && tmux switch-client -t ${TMUX_SESSION}:${TMUX_WINDOW} && tmux select-pane -t .${TMUX_PANE}"
fi

# Get location (git repo name or directory name)
if git rev-parse --git-dir > /dev/null 2>&1; then
    # We're in a git repo
    REPO_ROOT=$(git rev-parse --show-toplevel)
    LOCATION=$(basename "$REPO_ROOT")
else
    # Not in a git repo, use current directory name
    LOCATION=$(basename "$PWD")
fi

# Set title and message based on event type
case "$EVENT_TYPE" in
    "SessionEnd")
        TITLE="🤖 Claude Code Complete"
        MESSAGE="Repository: $LOCATION"
        ;;
    "AgentComplete")
        TITLE="🤖 Claude Agent Complete"
        MESSAGE="Repository: $LOCATION"
        ;;
    *)
        TITLE="🤖 Claude Code $EVENT_TYPE"
        MESSAGE="Repository: $LOCATION"
        ;;
esac

# Build terminal-notifier command
NOTIFY_CMD=(
    terminal-notifier
    -title "$TITLE"
    -message "$MESSAGE"
    -sound "default"
)

# Add subtitle if we have tmux info
if [ -n "$TMUX_INFO" ]; then
    NOTIFY_CMD+=(-subtitle "$TMUX_INFO")
fi

# Add execute command if available
if [ -n "$EXECUTE_CMD" ]; then
    NOTIFY_CMD+=(-execute "$EXECUTE_CMD")
fi

# Send the notification
"${NOTIFY_CMD[@]}"
