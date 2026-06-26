#!/bin/bash

# Shared agent notification hook for Claude, Pi, and Devin.
# Sends a desktop notification when an agent finishes; clicking it focuses the
# tmux pane (and raises the terminal app) the agent was running in.
#   macOS: terminal-notifier (-execute runs the click handler via Launch
#          Services, so it works after this script exits — no living process).
#   Linux: noti, falling back to notify-send.
#
# Usage: notify.sh [AGENT_LABEL]
#   AGENT_LABEL - shown in the title (e.g. "Claude", "Pi", "Devin"). Default: "Agent".

AGENT="${1:-Agent}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Resolve tmux's absolute path now. The click handler runs from terminal-notifier
# with a minimal PATH that won't include mise/homebrew, so a bare "tmux" fails.
TMUX_BIN="$(command -v tmux 2>/dev/null)"
if [ -z "$TMUX_BIN" ]; then
    for c in /opt/homebrew/bin/tmux /usr/local/bin/tmux "$HOME"/.local/share/mise/installs/tmux/*/bin/tmux; do
        [ -x "$c" ] && { TMUX_BIN="$c"; break; }
    done
fi

# Location: git repo name, else current directory name
if git rev-parse --git-dir > /dev/null 2>&1; then
    LOCATION=$(basename "$(git rev-parse --show-toplevel)")
else
    LOCATION=$(basename "$PWD")
fi

TITLE="🤖 ${AGENT} Complete"
MESSAGE="Repository: $LOCATION"

# tmux context: subtitle text + click-to-focus target
TMUX_INFO=""
TMUX_TARGET=""
if [ -n "$TMUX" ] && [ -n "$TMUX_BIN" ]; then
    TMUX_INFO=$("$TMUX_BIN" display-message -p '#S:#I.#P [#W]')
    TMUX_TARGET="$("$TMUX_BIN" display-message -p '#S'):$("$TMUX_BIN" display-message -p '#I').$("$TMUX_BIN" display-message -p '#P')"
fi

# Terminal app to raise on click, captured now (the click handler may run later
# in an environment without these vars). Maps to AppleScript application names.
# NOTE: inside tmux, $TERM_PROGRAM is "tmux", so we fall back to vendor-specific
# env vars and the attached client's terminfo name.
detect_term_app() {
    case "$TERM_PROGRAM" in
        ghostty|Ghostty) echo "Ghostty"; return ;;
        Apple_Terminal)  echo "Terminal"; return ;;
        iTerm.app)       echo "iTerm"; return ;;
        WezTerm)         echo "WezTerm"; return ;;
    esac
    if   [ -n "$GHOSTTY_BIN_DIR$GHOSTTY_RESOURCES_DIR" ]; then echo "Ghostty"; return; fi
    if   [ -n "$KITTY_WINDOW_ID" ];     then echo "kitty"; return; fi
    if   [ -n "$ALACRITTY_WINDOW_ID" ]; then echo "Alacritty"; return; fi
    if   [ -n "$WEZTERM_PANE" ];        then echo "WezTerm"; return; fi
    if [ -n "$TMUX" ] && [ -n "$TMUX_BIN" ]; then
        case "$("$TMUX_BIN" display-message -p '#{client_termname}' 2>/dev/null)" in
            *ghostty*)   echo "Ghostty" ;;
            *kitty*)     echo "kitty" ;;
            *alacritty*) echo "Alacritty" ;;
            *iterm*)     echo "iTerm" ;;
            *wezterm*)   echo "WezTerm" ;;
        esac
    fi
}
TERM_APP="$(detect_term_app)"

case "$(uname -s)" in
    Darwin)
        if command -v terminal-notifier > /dev/null 2>&1; then
            args=(-title "$TITLE" -message "$MESSAGE" -sound default)
            [ -n "$TMUX_INFO" ] && args+=(-subtitle "$TMUX_INFO")
            # Click anywhere on the notification → focus the pane. The handler
            # gets the tmux target, terminal app to raise, and tmux binary path.
            [ -n "$TMUX_TARGET" ] && args+=(-execute "$SCRIPT_DIR/notify-click-handler.sh $TMUX_TARGET $TERM_APP $TMUX_BIN")
            terminal-notifier "${args[@]}"
        fi
        ;;
    *)
        if command -v noti > /dev/null 2>&1; then
            noti -t "$TITLE" -m "$MESSAGE"
        elif command -v notify-send > /dev/null 2>&1; then
            notify-send "$TITLE" "$MESSAGE"
        fi
        ;;
esac

exit 0
