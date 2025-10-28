#!/bin/bash

# Tmux Rose Pine Theme Switcher
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
    # Rose Pine Dawn (Light theme)
    tmux set-option -g status-style "bg=#faf4ed,fg=#575279"
    tmux set-option -g pane-active-border-style "fg=#56949f"
    tmux set-option -g pane-border-style "fg=#dfdad9"
    tmux set-option -g window-status-format " #I:#W "
    tmux set-option -g window-status-current-format "#[bg=#56949f,fg=#faf4ed] #I:#W#{?window_zoomed_flag,  , }"
else
    # Rose Pine Main (Dark theme)
    tmux set-option -g status-style "bg=#191724,fg=#e0def4"
    tmux set-option -g pane-active-border-style "fg=#9ccfd8"
    tmux set-option -g pane-border-style "fg=#403d52"
    tmux set-option -g window-status-format " #I:#W "
    tmux set-option -g window-status-current-format "#[bg=#9ccfd8,fg=#191724] #I:#W#{?window_zoomed_flag,  , }"
fi
