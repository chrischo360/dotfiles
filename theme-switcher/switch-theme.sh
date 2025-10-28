#!/bin/bash

# Kanagawa Theme Switcher
# Automatically switches between light (Lotus) and dark (Wave) themes based on time
# Light mode: 6 AM - 7 PM
# Dark mode:  7 PM - 6 AM

THEME_DIR="$HOME/.config/theme-switcher"
STATE_FILE="$THEME_DIR/current-theme"
ALACRITTY_CONFIG="$HOME/dotfiles/alacritty/alacritty.toml"
TMUX_THEME_SCRIPT="$THEME_DIR/tmux-theme.sh"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to determine theme based on time
get_theme_by_time() {
    local hour=$(date +%H)

    # Light theme: 6 AM (06) to 7 PM (19)
    if [ "$hour" -ge 6 ] && [ "$hour" -lt 19 ]; then
        echo "light"
    else
        echo "dark"
    fi
}

# Function to get current theme from state file
get_current_theme() {
    if [ -f "$STATE_FILE" ]; then
        cat "$STATE_FILE"
    else
        echo "unknown"
    fi
}

# Function to switch Alacritty theme
switch_alacritty() {
    local theme=$1
    local colors_file="$THEME_DIR/alacritty-colors-${theme}.toml"

    if [ ! -f "$colors_file" ]; then
        echo -e "${RED}Error: Alacritty color file not found: $colors_file${NC}"
        return 1
    fi

    # Replace the colors section in alacritty.toml
    # This uses a temporary file approach
    local temp_file=$(mktemp)

    # Extract everything before the colors section
    sed -n '1,/^# Kanagawa/p' "$ALACRITTY_CONFIG" | head -n -1 > "$temp_file"

    # Add the new colors
    cat "$colors_file" >> "$temp_file"

    # Extract everything after the VI mode section
    sed -n '/^\[env\]/,$p' "$ALACRITTY_CONFIG" >> "$temp_file"

    # Replace the original file
    mv "$temp_file" "$ALACRITTY_CONFIG"

    echo -e "${GREEN}✓ Alacritty theme switched to $theme${NC}"
}

# Function to switch tmux theme
switch_tmux() {
    local theme=$1

    # Source the tmux theme script which will update colors
    if [ -n "$TMUX" ]; then
        tmux source-file "$TMUX_THEME_SCRIPT" 2>/dev/null
        echo -e "${GREEN}✓ Tmux theme switched to $theme${NC}"
    else
        echo -e "${YELLOW}⚠ Not in a tmux session, will apply on next tmux start${NC}"
    fi
}

# Function to notify Neovim instances
notify_neovim() {
    local theme=$1
    local bg="dark"
    local colorscheme="kanagawa-wave"

    if [ "$theme" = "light" ]; then
        bg="light"
        colorscheme="kanagawa-lotus"
    fi

    # Find all running Neovim instances and send the colorscheme command
    # This uses nvim --server if servernames are set
    for server in $(nvr --serverlist 2>/dev/null); do
        nvr --servername "$server" --remote-send "<Esc>:set background=${bg}<CR>:colorscheme ${colorscheme}<CR>" 2>/dev/null
    done

    echo -e "${GREEN}✓ Neovim instances notified (will apply on next launch)${NC}"
}

# Main switching logic
switch_theme() {
    local target_theme=$1
    local current_theme=$(get_current_theme)

    # If no target specified, determine by time
    if [ -z "$target_theme" ]; then
        target_theme=$(get_theme_by_time)
    fi

    # Check if already on target theme
    if [ "$current_theme" = "$target_theme" ]; then
        echo -e "${BLUE}Already on $target_theme theme${NC}"
        return 0
    fi

    echo -e "${BLUE}Switching to $target_theme theme...${NC}"

    # Switch each component
    switch_alacritty "$target_theme"
    switch_tmux "$target_theme"
    notify_neovim "$target_theme"

    # Update state file
    echo "$target_theme" > "$STATE_FILE"

    echo -e "${GREEN}✓ Theme switched to $target_theme${NC}"
    echo -e "${YELLOW}Note: Restart Alacritty for full effect${NC}"
}

# Parse command line arguments
case "${1:-auto}" in
    light)
        switch_theme "light"
        ;;
    dark)
        switch_theme "dark"
        ;;
    auto)
        switch_theme ""
        ;;
    status)
        current=$(get_current_theme)
        auto=$(get_theme_by_time)
        echo -e "Current theme: ${GREEN}$current${NC}"
        echo -e "Auto-detected theme: ${BLUE}$auto${NC}"
        ;;
    *)
        echo "Usage: $0 {light|dark|auto|status}"
        echo "  light  - Switch to light theme (Kanagawa Lotus)"
        echo "  dark   - Switch to dark theme (Kanagawa Wave)"
        echo "  auto   - Auto-detect based on time (default)"
        echo "  status - Show current theme status"
        exit 1
        ;;
esac
