#!/bin/bash

# Tmux Kanagawa Theme Switcher
# Dynamically loads light or dark theme based on time

THEME_DIR="$HOME/.config/theme-switcher"
STATE_FILE="$THEME_DIR/current-theme"

# Function to get current theme
get_current_theme() {
    if [ -f "$STATE_FILE" ]; then
        cat "$STATE_FILE"
    else
        # Default to time-based detection
        local hour=$(date +%H)
        if [ "$hour" -ge 6 ] && [ "$hour" -lt 19 ]; then
            echo "light"
        else
            echo "dark"
        fi
    fi
}

# Get the theme
THEME=$(get_current_theme)

# Apply theme colors
if [ "$THEME" = "light" ]; then
    # Kanagawa Lotus (Light theme)
    tmux set-option -g status-style "bg=#e7dba0,fg=#545464"
    tmux set-option -g pane-active-border-style "fg=#4d699b"
    tmux set-option -g pane-border-style "fg=#c9cbd1"
    tmux set-option -g window-status-format " #I:#W "
    tmux set-option -g window-status-current-format "#[bg=#4d699b,fg=#f2ecbc] #I:#W#{?window_zoomed_flag,  , }"
else
    # Kanagawa Wave (Dark theme)
    tmux set-option -g status-style "bg=#16161d,fg=#dcd7ba"
    tmux set-option -g pane-active-border-style "fg=#7e9cd8"
    tmux set-option -g pane-border-style "fg=#54546d"
    tmux set-option -g window-status-format " #I:#W "
    tmux set-option -g window-status-current-format "#[bg=#7e9cd8,fg=#1f1f28] #I:#W#{?window_zoomed_flag,  , }"
fi
