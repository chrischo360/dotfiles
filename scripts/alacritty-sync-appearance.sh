#!/bin/bash
# Alacritty Appearance Sync Script
# Automatically switches Alacritty theme based on macOS appearance (light/dark)
# Can be run manually or triggered by LaunchAgent

ALACRITTY_CONFIG="$HOME/dotfiles/alacritty/alacritty.toml"
THEME_PREFS="$HOME/.config/alacritty/theme-prefs.conf"
THEMES_DIR="$HOME/.config/alacritty/themes/themes"

# Function to detect macOS appearance
get_macos_appearance() {
    # Read the macOS interface style
    # Returns "Dark" if dark mode, empty string if light mode
    local appearance=$(defaults read -g AppleInterfaceStyle 2>/dev/null)

    if [[ "$appearance" == "Dark" ]]; then
        echo "dark"
    else
        echo "light"
    fi
}

# Function to load theme preferences
load_preferences() {
    if [[ ! -f "$THEME_PREFS" ]]; then
        echo "Error: Theme preferences file not found: $THEME_PREFS"
        exit 1
    fi

    # Source the preferences file
    source "$THEME_PREFS"
}

# Function to apply theme
apply_theme() {
    local theme="$1"
    local theme_file="$THEMES_DIR/${theme}.toml"

    # Check if theme file exists
    if [[ ! -f "$theme_file" ]]; then
        echo "Warning: Theme file not found: $theme_file"
        echo "Using fallback theme: dracula"
        theme="dracula"
    fi

    # Update the import line in alacritty.toml
    if grep -q "^\[general\]" "$ALACRITTY_CONFIG"; then
        # Update existing import
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

    # Trigger config reload
    touch "$ALACRITTY_CONFIG"

    echo "✓ Applied theme: $theme"
}

# Main logic
main() {
    # Detect current macOS appearance
    appearance=$(get_macos_appearance)
    echo "Detected macOS appearance: $appearance mode"

    # Load user preferences
    load_preferences

    # Apply appropriate theme
    if [[ "$appearance" == "dark" ]]; then
        echo "Applying dark theme: $DARK_THEME"
        apply_theme "$DARK_THEME"
    else
        echo "Applying light theme: $LIGHT_THEME"
        apply_theme "$LIGHT_THEME"
    fi
}

# Run main function
main "$@"
