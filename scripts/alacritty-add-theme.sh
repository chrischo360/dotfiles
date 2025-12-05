#!/bin/bash
# Helper script to add new themes to the Alacritty theme registry
# Usage: ./alacritty-add-theme.sh <theme-name> <light|dark> <display-name>
# Example: ./alacritty-add-theme.sh gruvbox_dark dark "Gruvbox Dark"

REGISTRY="$HOME/.config/alacritty/theme-registry.conf"
THEMES_DIR="$HOME/.config/alacritty/themes/themes"

# Check arguments
if [[ $# -ne 3 ]]; then
    echo "Usage: $0 <theme-name> <light|dark> <display-name>"
    echo ""
    echo "Examples:"
    echo "  $0 gruvbox_dark dark \"Gruvbox Dark\""
    echo "  $0 solarized_light light \"Solarized Light\""
    echo ""
    echo "Available theme files:"
    ls "$THEMES_DIR" | sed 's/\.toml$//' | head -20
    exit 1
fi

THEME_NAME="$1"
THEME_TYPE="$2"
DISPLAY_NAME="$3"

# Validate theme type
if [[ "$THEME_TYPE" != "light" && "$THEME_TYPE" != "dark" ]]; then
    echo "Error: Theme type must be 'light' or 'dark'"
    exit 1
fi

# Check if theme file exists
THEME_FILE="$THEMES_DIR/${THEME_NAME}.toml"
if [[ ! -f "$THEME_FILE" ]]; then
    echo "Error: Theme file not found: $THEME_FILE"
    echo ""
    echo "Available themes:"
    ls "$THEMES_DIR" | sed 's/\.toml$//' | grep -i "$THEME_NAME"
    exit 1
fi

# Check if theme already in registry
if grep -q "^${THEME_NAME}|" "$REGISTRY"; then
    echo "Warning: Theme '$THEME_NAME' already exists in registry"
    echo "Current entry:"
    grep "^${THEME_NAME}|" "$REGISTRY"
    read -p "Overwrite? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Cancelled"
        exit 0
    fi
    # Remove old entry
    sed -i '' "/^${THEME_NAME}|/d" "$REGISTRY"
fi

# Add to registry
echo "${THEME_NAME}|${THEME_TYPE}|${DISPLAY_NAME}" >> "$REGISTRY"

echo "✓ Added theme to registry:"
echo "  Name: $THEME_NAME"
echo "  Type: $THEME_TYPE"
echo "  Display: $DISPLAY_NAME"
echo ""
echo "Theme will now appear in the theme picker!"
