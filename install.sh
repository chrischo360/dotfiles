#!/bin/bash

# Dotfiles Installation Script
# Automatically creates symlinks and sets up development environment

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get the directory where this script is located
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     Dotfiles Installation Script      ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}Dotfiles directory: ${DOTFILES_DIR}${NC}"
echo ""

# Function to create symlink with backup
create_symlink() {
    local source=$1
    local target=$2
    local backup_dir="${HOME}/.dotfiles-backup-$(date +%Y%m%d-%H%M%S)"

    # Create parent directory if it doesn't exist
    mkdir -p "$(dirname "$target")"

    # Backup existing file/directory if it exists and is not already a symlink
    if [ -e "$target" ] && [ ! -L "$target" ]; then
        echo -e "${YELLOW}  ⚠ Backing up existing: $target${NC}"
        mkdir -p "$backup_dir"
        mv "$target" "$backup_dir/"
    fi

    # Remove existing symlink if it exists
    if [ -L "$target" ]; then
        rm "$target"
    fi

    # Create symlink
    ln -sf "$source" "$target"
    echo -e "${GREEN}  ✓ Linked: $target -> $source${NC}"
}

# Main installation steps
echo -e "${BLUE}[1/5] Installing Homebrew packages...${NC}"

if command -v brew &> /dev/null; then
    echo -e "${GREEN}  ✓ Homebrew detected${NC}"
    if [ -f "$DOTFILES_DIR/Brewfile" ]; then
        echo -e "${YELLOW}  Installing packages from Brewfile...${NC}"
        brew bundle --file="$DOTFILES_DIR/Brewfile" --no-lock
        echo -e "${GREEN}  ✓ Homebrew packages installed${NC}"
    else
        echo -e "${YELLOW}  ⚠ Brewfile not found, skipping package installation${NC}"
    fi
else
    echo -e "${RED}  ✗ Homebrew not installed${NC}"
    echo -e "${YELLOW}  Install Homebrew first: /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\"${NC}"
    echo -e "${YELLOW}  Then re-run this script to install packages${NC}"
fi

echo ""
echo -e "${BLUE}[2/5] Initializing git submodules...${NC}"

if git -C "$DOTFILES_DIR" rev-parse --git-dir > /dev/null 2>&1; then
    echo -e "${YELLOW}  Updating git submodules...${NC}"
    git -C "$DOTFILES_DIR" submodule update --init --recursive
    echo -e "${GREEN}  ✓ Git submodules initialized${NC}"
else
    echo -e "${RED}  ✗ Not a git repository${NC}"
    echo -e "${YELLOW}  ⚠ Plugin submodules may not be initialized${NC}"
fi

echo ""
echo -e "${BLUE}[3/5] Creating symlinks...${NC}"

# Zsh
create_symlink "$DOTFILES_DIR/zsh/.zshrc" "$HOME/.zshrc"

# tmux
create_symlink "$DOTFILES_DIR/tmux/tmux.conf" "$HOME/.tmux.conf"

# Git
create_symlink "$DOTFILES_DIR/git/gitconfig" "$HOME/.gitconfig"

# AeroSpace
create_symlink "$DOTFILES_DIR/aerospace/aerospace.toml" "$HOME/.aerospace.toml"

# Hammerspoon
create_symlink "$DOTFILES_DIR/hammerspoon" "$HOME/.hammerspoon"

# Create ~/.config directory
mkdir -p "$HOME/.config"

# Alacritty
create_symlink "$DOTFILES_DIR/alacritty" "$HOME/.config/alacritty"

# Neovim
create_symlink "$DOTFILES_DIR/nvim" "$HOME/.config/nvim"

# ccstatusline
create_symlink "$DOTFILES_DIR/ccstatusline" "$HOME/.config/ccstatusline"

# Claude Code
mkdir -p "$HOME/.claude"
create_symlink "$DOTFILES_DIR/claude/settings.json" "$HOME/.claude/settings.json"
create_symlink "$DOTFILES_DIR/claude/scripts/statusline.sh" "$HOME/.claude/statusline.sh"
create_symlink "$DOTFILES_DIR/claude/agents" "$HOME/.claude/agents"
create_symlink "$DOTFILES_DIR/claude/CLAUDE.md" "$HOME/.claude/CLAUDE.md"

echo ""
echo -e "${BLUE}[4/5] Making scripts executable...${NC}"

# Make all shell scripts executable
find "$DOTFILES_DIR/claude/scripts" -name "*.sh" -exec chmod +x {} \;
find "$DOTFILES_DIR/alacritty/scripts" -name "*.sh" -exec chmod +x {} \;
find "$DOTFILES_DIR/raycast" -name "*.sh" -exec chmod +x {} \;
find "$DOTFILES_DIR/tmux/scripts" -name "*.sh" -exec chmod +x {} \;
chmod +x "$DOTFILES_DIR/claude/status"

# Browser automation scripts
if [ -d "$DOTFILES_DIR/scripts/browser" ]; then
    echo -e "${YELLOW}  Setting up browser automation scripts...${NC}"

    # Make all .mjs and .sh scripts executable
    find "$DOTFILES_DIR/scripts/browser" -name "*.mjs" -exec chmod +x {} \;
    find "$DOTFILES_DIR/scripts/browser" -name "*.sh" -exec chmod +x {} \;

    # Install npm dependencies
    if [ -f "$DOTFILES_DIR/scripts/browser/package.json" ]; then
        echo -e "${YELLOW}  Installing npm dependencies...${NC}"
        cd "$DOTFILES_DIR/scripts/browser"
        npm install --silent

        # Install Playwright Chromium browser
        echo -e "${YELLOW}  Installing Playwright Chromium...${NC}"
        npx playwright install chromium --with-deps

        cd "$DOTFILES_DIR"
        echo -e "${GREEN}  ✓ Browser automation setup complete${NC}"
    fi
fi

echo -e "${GREEN}  ✓ Scripts made executable${NC}"

echo ""
echo -e "${BLUE}[5/5] Verifying package installation...${NC}"

check_command() {
    if command -v "$1" &> /dev/null; then
        echo -e "${GREEN}  ✓ $1${NC}"
        return 0
    else
        echo -e "${RED}  ✗ $1 (not installed)${NC}"
        return 1
    fi
}

# Check essential commands
check_command "brew" || echo -e "${YELLOW}    Install: /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\"${NC}"
check_command "git"
check_command "tmux" || echo -e "${YELLOW}    Run: brew bundle --file=~/dotfiles/Brewfile${NC}"
check_command "nvim" || echo -e "${YELLOW}    Run: brew bundle --file=~/dotfiles/Brewfile${NC}"
check_command "terminal-notifier" || echo -e "${YELLOW}    Run: brew bundle --file=~/dotfiles/Brewfile${NC}"

# Check browser automation setup
if [ -d "$DOTFILES_DIR/scripts/browser/node_modules" ]; then
    echo -e "${GREEN}  ✓ Browser automation (Playwright)${NC}"
else
    echo -e "${RED}  ✗ Browser automation (npm dependencies missing)${NC}"
    echo -e "${YELLOW}    Run: cd ~/dotfiles/scripts/browser && npm install && npx playwright install chromium${NC}"
fi

# Check if Alacritty is installed
if [ -d "/Applications/Alacritty.app" ]; then
    echo -e "${GREEN}  ✓ Alacritty${NC}"
else
    echo -e "${RED}  ✗ Alacritty (not installed)${NC}"
    echo -e "${YELLOW}    Run: brew bundle --file=~/dotfiles/Brewfile${NC}"
fi

# Check if AeroSpace is installed
if [ -d "/Applications/AeroSpace.app" ]; then
    echo -e "${GREEN}  ✓ AeroSpace${NC}"
else
    echo -e "${RED}  ✗ AeroSpace (not installed)${NC}"
    echo -e "${YELLOW}    Run: brew bundle --file=~/dotfiles/Brewfile${NC}"
fi

# Check if Hammerspoon is installed
if [ -d "/Applications/Hammerspoon.app" ]; then
    echo -e "${GREEN}  ✓ Hammerspoon${NC}"
else
    echo -e "${RED}  ✗ Hammerspoon (not installed)${NC}"
    echo -e "${YELLOW}    Run: brew bundle --file=~/dotfiles/Brewfile${NC}"
fi

# Check if Raycast is installed
if [ -d "/Applications/Raycast.app" ]; then
    echo -e "${GREEN}  ✓ Raycast${NC}"
    echo -e "${YELLOW}    Note: Raycast is optional and not in Brewfile${NC}"
else
    echo -e "${YELLOW}  ⚠ Raycast (optional - not installed)${NC}"
    echo -e "${YELLOW}    Install manually: brew install --cask raycast${NC}"
fi

# Check JetBrainsMono Nerd Font
if fc-list 2>/dev/null | grep -i "JetBrainsMono Nerd Font" > /dev/null || \
   ls ~/Library/Fonts/ 2>/dev/null | grep -i "JetBrainsMono" > /dev/null || \
   ls /Library/Fonts/ 2>/dev/null | grep -i "JetBrainsMono" > /dev/null; then
    echo -e "${GREEN}  ✓ JetBrainsMono Nerd Font${NC}"
else
    echo -e "${RED}  ✗ JetBrainsMono Nerd Font (not installed)${NC}"
    echo -e "${YELLOW}    Run: brew bundle --file=~/dotfiles/Brewfile${NC}"
fi

echo ""
echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║     Installation Complete! 🎉         ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}Next steps:${NC}"
echo -e "  1. Restart your terminal or run: ${YELLOW}exec zsh${NC}"
echo -e "  2. If packages are missing, run: ${YELLOW}brew bundle --file=~/dotfiles/Brewfile${NC}"
echo -e "  3. Setup Raycast script commands (optional):"
echo -e "     - Open Raycast Settings (⌘,)"
echo -e "     - Extensions → Script Commands"
echo -e "     - Add directory: ${YELLOW}$DOTFILES_DIR/raycast${NC}"
echo ""
echo -e "${BLUE}Configuration locations:${NC}"
echo -e "  Brewfile:   ~/dotfiles/Brewfile"
echo -e "  Zsh:        ~/.zshrc"
echo -e "  tmux:       ~/.tmux.conf"
echo -e "  Neovim:     ~/.config/nvim"
echo -e "  Alacritty:  ~/.config/alacritty"
echo -e "  Claude:     ~/.claude/settings.json"
echo ""
