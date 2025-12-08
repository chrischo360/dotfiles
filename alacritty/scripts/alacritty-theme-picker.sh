#!/bin/bash
# Alacritty Theme Picker - Opens in new Alacritty window
# This wrapper launches a new Alacritty window outside tmux for theme selection
# Usage: Run this from within tmux or anywhere else

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
THEME_SCRIPT="$SCRIPT_DIR/alacritty-theme.sh"

# Check if we're in tmux or if user wants dedicated window
if [ -n "$TMUX" ] || [ "$1" = "--window" ]; then
    # Launch new Alacritty window without tmux
    /Applications/Alacritty.app/Contents/MacOS/alacritty \
        --title "Alacritty Theme Picker" \
        -e zsh -l -c "
            # Display instructions
            clear
            echo '═══════════════════════════════════════════════════════'
            echo '  Alacritty Theme Picker - Live Preview'
            echo '═══════════════════════════════════════════════════════'
            echo ''
            echo 'As you navigate with arrow keys, THIS window will'
            echo 'change colors to preview each theme in real-time!'
            echo ''
            echo 'Press ENTER to select a theme'
            echo 'Press ESC to cancel and keep your current theme'
            echo ''
            echo -n 'Press ENTER to start browsing themes...'
            read -r
            echo ''

            # Run the theme picker
            $THEME_SCRIPT

            # Wait a moment before closing
            echo ''
            echo 'Theme selection complete!'
            sleep 1
        " &

    echo "✓ Opened theme picker in new Alacritty window"
    echo "  Watch the new window change colors as you navigate!"
else
    # Not in tmux - run directly for immediate preview
    clear
    echo "═══════════════════════════════════════════════════════"
    echo "  Alacritty Theme Picker - Live Preview"
    echo "═══════════════════════════════════════════════════════"
    echo ""
    echo "Navigate with arrow keys to preview themes in real-time"
    echo "Press ENTER to select, ESC to cancel"
    echo ""
    echo -n "Press ENTER to start..."
    read -r
    echo ""
    exec "$THEME_SCRIPT"
fi
