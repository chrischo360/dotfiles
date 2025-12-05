#!/bin/bash
# Alacritty Theme Switcher
# Usage: ./alacritty-theme.sh <theme-name>
# Example: ./alacritty-theme.sh flat_remix
# Or: ./alacritty-theme.sh (interactive mode with fzf)

ALACRITTY_CONFIG="$HOME/dotfiles/alacritty/alacritty.toml"
THEMES_DIR="$HOME/.config/alacritty/themes/themes"
REGISTRY="$HOME/.config/alacritty/theme-registry.conf"
THEME_PREFS="$HOME/.config/alacritty/theme-prefs.conf"

# Function to list available themes
list_themes() {
    echo "Available themes:"
    ls "$THEMES_DIR" | sed 's/\.toml$//' | sort
}

# Function to switch theme
switch_theme() {
    local theme="$1"
    local theme_file="$THEMES_DIR/${theme}.toml"

    # Check if theme exists
    if [[ ! -f "$theme_file" ]]; then
        echo "Error: Theme '$theme' not found!"
        echo ""
        list_themes
        exit 1
    fi

    # Update the import line in alacritty.toml
    if grep -q "^\[general\]" "$ALACRITTY_CONFIG"; then
        # Update existing import (macOS compatible sed)
        sed -i '' '/import = \[/,/\]/c\
import = [\
  "~/.config/alacritty/themes/themes/'"$theme"'.toml"\
]
' "$ALACRITTY_CONFIG"
    else
        # Add import section at the beginning
        temp_file=$(mktemp)
        echo -e "[general]\nimport = [\n  \"~/.config/alacritty/themes/themes/$theme.toml\"\n]\n" > "$temp_file"
        cat "$ALACRITTY_CONFIG" >> "$temp_file"
        mv "$temp_file" "$ALACRITTY_CONFIG"
    fi

    # Trigger config reload by touching the file
    touch "$ALACRITTY_CONFIG"

    echo "✓ Switched to theme: $theme"
    echo "  Theme should reload automatically (if live_config_reload is enabled)"
}

# Function to apply theme without confirmation message
apply_theme_silent() {
    local theme="$1"
    local theme_file="$THEMES_DIR/${theme}.toml"

    if [[ ! -f "$theme_file" ]]; then
        return 1
    fi

    # Update the import line
    sed -i '' '/import = \[/,/\]/c\
import = [\
  "~/.config/alacritty/themes/themes/'"$theme"'.toml"\
]
' "$ALACRITTY_CONFIG"

    # Trigger reload
    touch "$ALACRITTY_CONFIG"
}

# Function to detect macOS appearance
get_macos_appearance() {
    local appearance=$(defaults read -g AppleInterfaceStyle 2>/dev/null)
    if [[ "$appearance" == "Dark" ]]; then
        echo "dark"
    else
        echo "light"
    fi
}

# Function to save theme preference
save_theme_preference() {
    local theme="$1"
    local appearance="$2"

    # Update the preference file
    if [[ "$appearance" == "dark" ]]; then
        sed -i '' "s/^DARK_THEME=.*/DARK_THEME=\"$theme\"/" "$THEME_PREFS"
        echo "  Saved as your default dark theme"
    else
        sed -i '' "s/^LIGHT_THEME=.*/LIGHT_THEME=\"$theme\"/" "$THEME_PREFS"
        echo "  Saved as your default light theme"
    fi
}

# Interactive mode with fzf and LIVE preview - ALL THEMES
interactive_mode() {
    if ! command -v fzf &> /dev/null; then
        echo "Error: fzf not found. Install it or use: $0 <theme-name>"
        exit 1
    fi

    # Check if registry exists
    if [[ ! -f "$REGISTRY" ]]; then
        echo "Error: Theme registry not found: $REGISTRY"
        exit 1
    fi

    # Detect current appearance (for saving preferences)
    appearance=$(get_macos_appearance)

    # Save current theme to restore if cancelled
    current_theme=$(grep 'themes/themes/' "$ALACRITTY_CONFIG" | sed 's/.*themes\/\(.*\)\.toml.*/\1/')

    # Get all themes from registry (not filtered by appearance)
    # Format: theme_name|type|display_name
    all_themes=$(grep -v '^#' "$REGISTRY" | grep -v '^$' | awk -F'|' '{print $1 " - " $3}')

    if [[ -z "$all_themes" ]]; then
        echo "Error: No themes found in registry"
        exit 1
    fi

    # Create a preview script that also applies the theme
    preview_script=$(mktemp)
    cat > "$preview_script" << 'PREVIEW_EOF'
#!/bin/bash
THEME_LINE="$1"
THEMES_DIR="$2"
ALACRITTY_CONFIG="$3"

# Extract theme name (before the ' - ')
THEME=$(echo "$THEME_LINE" | cut -d' ' -f1)

# Apply the theme
sed -i '' "/import = \\[/,/\\]/c\\
import = [\\
  \"~/.config/alacritty/themes/themes/${THEME}.toml\"\\
]
" "$ALACRITTY_CONFIG" && touch "$ALACRITTY_CONFIG"

# Show preview info
echo "Theme: $THEME_LINE"
echo ""
grep -E '(background|foreground|color[0-9]|red|green|blue|yellow)' "$THEMES_DIR/${THEME}.toml" 2>/dev/null | head -20
PREVIEW_EOF
    chmod +x "$preview_script"

    # Show header for all themes
    header="All Themes (live preview - use arrow keys)"

    # Get theme selection from all themes
    theme_selection=$(echo "$all_themes" | fzf \
        --preview "$preview_script {} $THEMES_DIR $ALACRITTY_CONFIG" \
        --preview-window=right:60% \
        --header="$header" \
        --border \
        --height=80%)

    # Clean up temp script
    rm -f "$preview_script"

    if [[ -n "$theme_selection" ]]; then
        # Extract theme name from selection
        theme=$(echo "$theme_selection" | cut -d' ' -f1)

        # User selected a theme - keep it and save preference
        echo "✓ Selected theme: $theme_selection"
        save_theme_preference "$theme" "$appearance"
    else
        # User cancelled - restore original theme
        echo "Cancelled - restoring original theme: $current_theme"
        apply_theme_silent "$current_theme"
    fi
}

# Main logic
case "$1" in
    "")
        # No arguments - try interactive mode
        interactive_mode
        ;;
    "list")
        list_themes
        ;;
    "-h"|"--help")
        echo "Alacritty Theme Switcher"
        echo ""
        echo "Usage:"
        echo "  $0              # Interactive mode (requires fzf)"
        echo "  $0 <theme>      # Switch to specific theme"
        echo "  $0 list         # List available themes"
        echo "  $0 --help       # Show this help"
        echo ""
        echo "Examples:"
        echo "  $0 flat_remix"
        echo "  $0 dracula"
        echo "  $0 rose-pine"
        ;;
    *)
        switch_theme "$1"
        ;;
esac
