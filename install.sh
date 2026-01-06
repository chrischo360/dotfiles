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

# Function to process JSON templates with path substitution
substitute_json_template() {
    local template=$1
    local output=$2

    # Paths for substitution
    local home="$HOME"
    local dotfiles="$DOTFILES_DIR"
    local codebase="${HOME}/codebase"
    local local_bin="${HOME}/.local/bin"
    local pal_server="${HOME}/pal-mcp-server/pal-mcp-server"

    # Create parent directory if needed
    mkdir -p "$(dirname "$output")"

    # Substitute placeholders
    sed -e "s|{{home}}|$home|g" \
        -e "s|{{dotfiles}}|$dotfiles|g" \
        -e "s|{{codebase}}|$codebase|g" \
        -e "s|{{local_bin}}|$local_bin|g" \
        -e "s|{{pal_server}}|$pal_server|g" \
        "$template" > "$output"

    echo -e "${GREEN}  ✓ Generated: $output${NC}"
}

# Main installation steps
echo -e "${BLUE}[1/6] Installing mise (dev tools manager)...${NC}"

# Install mise if not present
if ! command -v mise &> /dev/null; then
    echo -e "${YELLOW}  Installing mise...${NC}"
    curl https://mise.run | sh

    # Add mise to PATH for this session
    export PATH="$HOME/.local/bin:$PATH"

    # Verify installation
    if command -v mise &> /dev/null; then
        echo -e "${GREEN}  ✓ mise installed successfully${NC}"
    else
        echo -e "${RED}  ✗ mise installation failed${NC}"
        echo -e "${YELLOW}  You may need to add ~/.local/bin to your PATH${NC}"
    fi
else
    echo -e "${GREEN}  ✓ mise already installed${NC}"
fi

# Install tools from .mise.toml
if command -v mise &> /dev/null && [ -f "$DOTFILES_DIR/.mise.toml" ]; then
    echo -e "${YELLOW}  Installing development tools from .mise.toml...${NC}"
    echo -e "${YELLOW}  (This may take several minutes on first run)${NC}"

    # Load environment variables from .env (includes GITHUB_TOKEN for aqua backend)
    if [ -f "$DOTFILES_DIR/.env" ]; then
        echo -e "${YELLOW}  Loading environment variables from .env...${NC}"
        set -a
        source "$DOTFILES_DIR/.env"
        set +a
        # Export AQUA_GITHUB_TOKEN for mise's aqua backend
        export AQUA_GITHUB_TOKEN="${GITHUB_TOKEN}"
    else
        echo -e "${YELLOW}  ⚠ .env not found, aqua backend may hit GitHub API rate limits${NC}"
    fi

    # Change to dotfiles directory so mise picks up .mise.toml
    cd "$DOTFILES_DIR"

    # Install Java first (required by Scala)
    echo -e "${YELLOW}  Installing Java first (required by Scala)...${NC}"
    mise install java || echo -e "${YELLOW}  ⚠ Java installation had issues, continuing...${NC}"

    # Activate mise environment to make Java available in PATH for Scala
    eval "$(mise activate bash)"

    # Install remaining tools
    echo -e "${YELLOW}  Installing remaining tools...${NC}"
    mise install || echo -e "${YELLOW}  ⚠ Some tools failed to install, check output above${NC}"

    echo -e "${GREEN}  ✓ mise tools installed${NC}"
else
    echo -e "${YELLOW}  ⚠ .mise.toml not found, skipping tool installation${NC}"
fi

echo ""
echo -e "${BLUE}[2/6] Installing macOS-specific packages...${NC}"

# Detect OS
OS="$(uname -s)"

if [[ "$OS" == "Darwin" ]]; then
    # macOS - install Homebrew packages
    if command -v brew &> /dev/null; then
        echo -e "${GREEN}  ✓ Homebrew detected${NC}"
        if [ -f "$DOTFILES_DIR/Brewfile.macos" ]; then
            echo -e "${YELLOW}  Installing macOS packages from Brewfile.macos...${NC}"
            brew bundle --file="$DOTFILES_DIR/Brewfile.macos"
            echo -e "${GREEN}  ✓ macOS packages installed${NC}"
        else
            echo -e "${YELLOW}  ⚠ Brewfile.macos not found, skipping package installation${NC}"
        fi
    else
        echo -e "${RED}  ✗ Homebrew not installed${NC}"
        echo -e "${YELLOW}  Install Homebrew first: /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\"${NC}"
        echo -e "${YELLOW}  Then re-run this script to install macOS packages${NC}"
    fi
else
    echo -e "${YELLOW}  ⚠ Not on macOS - skipping Homebrew packages${NC}"
    echo -e "${YELLOW}  Most tools are installed via mise instead${NC}"
fi

echo ""
echo -e "${BLUE}[3/6] Initializing git submodules...${NC}"

if git -C "$DOTFILES_DIR" rev-parse --git-dir > /dev/null 2>&1; then
    echo -e "${YELLOW}  Updating git submodules...${NC}"
    git -C "$DOTFILES_DIR" submodule update --init --recursive
    echo -e "${GREEN}  ✓ Git submodules initialized${NC}"
else
    echo -e "${RED}  ✗ Not a git repository${NC}"
    echo -e "${YELLOW}  ⚠ Plugin submodules may not be initialized${NC}"
fi

echo ""
echo -e "${BLUE}[4/6] Setting up environment variables...${NC}"

# Copy .env.example to .env if .env doesn't exist
if [ ! -f "$DOTFILES_DIR/.env" ]; then
    if [ -f "$DOTFILES_DIR/.env.example" ]; then
        cp "$DOTFILES_DIR/.env.example" "$DOTFILES_DIR/.env"
        echo -e "${GREEN}  ✓ Created .env from .env.example${NC}"
        echo -e "${YELLOW}  ⚠ Edit $DOTFILES_DIR/.env and add your API keys${NC}"
    fi
else
    echo -e "${GREEN}  ✓ .env already exists${NC}"
fi

echo ""
echo -e "${BLUE}[5/6] Creating symlinks...${NC}"

# Zsh
create_symlink "$DOTFILES_DIR/zsh/.zshrc" "$HOME/.zshrc"

# tmux
create_symlink "$DOTFILES_DIR/tmux/tmux.conf" "$HOME/.tmux.conf"
create_symlink "$DOTFILES_DIR/tmux/scripts" "$HOME/.config/tmux/scripts"

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
create_symlink "$DOTFILES_DIR/claude/ccstatusline" "$HOME/.config/ccstatusline"

# mise global config (makes tools available everywhere)
mkdir -p "$HOME/.config/mise"
create_symlink "$DOTFILES_DIR/.mise.toml" "$HOME/.config/mise/config.toml"

# Claude Code
mkdir -p "$HOME/.claude"
substitute_json_template "$DOTFILES_DIR/claude/settings.json.template" "$HOME/.claude/settings.json"
create_symlink "$DOTFILES_DIR/claude/agents" "$HOME/.claude/agents"
create_symlink "$DOTFILES_DIR/claude/commands" "$HOME/.claude/commands"
create_symlink "$DOTFILES_DIR/claude/CLAUDE.md" "$HOME/.claude/CLAUDE.md"

# Gemini CLI
mkdir -p "$HOME/.gemini"
substitute_json_template "$DOTFILES_DIR/gemini/settings.json.template" "$HOME/.gemini/settings.json"

# Create stable binary symlink
if command -v npm &> /dev/null; then
    NPM_GLOBAL_BIN="$(npm bin -g)"
    if [ -f "$NPM_GLOBAL_BIN/gemini" ]; then
        create_symlink "$NPM_GLOBAL_BIN/gemini" "$HOME/.local/bin/gemini"
        echo -e "${GREEN}  ✓ Gemini CLI binary linked${NC}"
    else
        echo -e "${YELLOW}  ⚠ Gemini CLI not found. Install with: npm install -g @google/gemini-cli${NC}"
    fi
else
    echo -e "${YELLOW}  ⚠ npm not found. Ensure mise tools are installed${NC}"
fi

# Cursor AI
echo -e "${YELLOW}  Setting up Cursor AI configuration...${NC}"
mkdir -p "$HOME/.cursor/User"
create_symlink "$DOTFILES_DIR/cursor/User/settings.json" "$HOME/.cursor/User/settings.json"
create_symlink "$DOTFILES_DIR/cursor/mcp.json" "$HOME/.cursor/mcp.json"
create_symlink "$DOTFILES_DIR/cursor/cli-config.json" "$HOME/.cursor/cli-config.json"
echo -e "${GREEN}  ✓ Cursor AI configuration linked${NC}"

echo ""
echo -e "${BLUE}[6/6] Making scripts executable...${NC}"

# Make all shell scripts executable
find "$DOTFILES_DIR/claude/scripts" -type f -name "*.sh" -exec chmod +x {} \;
find "$DOTFILES_DIR/claude/hooks" -type f -name "*.sh" -exec chmod +x {} \;
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
echo -e "${BLUE}[7/7] Verifying installation...${NC}"

# OS already detected earlier

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
check_command "mise" || echo -e "${YELLOW}    Install: curl https://mise.run | sh${NC}"
check_command "git" || echo -e "${YELLOW}    Run: cd $DOTFILES_DIR && mise install${NC}"
check_command "tmux" || echo -e "${YELLOW}    Run: cd $DOTFILES_DIR && mise install${NC}"
check_command "nvim" || echo -e "${YELLOW}    Run: cd $DOTFILES_DIR && mise install${NC}"
check_command "fzf" || echo -e "${YELLOW}    Run: cd $DOTFILES_DIR && mise install${NC}"
check_command "rg" || echo -e "${YELLOW}    Run: cd $DOTFILES_DIR && mise install${NC}"

if [[ "$OS" == "Darwin" ]]; then
    check_command "brew" || echo -e "${YELLOW}    Install: /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\"${NC}"
    check_command "terminal-notifier" || echo -e "${YELLOW}    Run: brew bundle --file=$DOTFILES_DIR/Brewfile.macos${NC}"
fi

# Check browser automation setup
if [ -d "$DOTFILES_DIR/scripts/browser/node_modules" ]; then
    echo -e "${GREEN}  ✓ Browser automation (Playwright)${NC}"
else
    echo -e "${RED}  ✗ Browser automation (npm dependencies missing)${NC}"
    echo -e "${YELLOW}    Run: cd $DOTFILES_DIR/scripts/browser && npm install && npx playwright install chromium${NC}"
fi

# Platform-specific application checks
if [[ "$OS" == "Darwin" ]]; then
    # macOS-specific checks
    if [ -d "/Applications/Alacritty.app" ]; then
        echo -e "${GREEN}  ✓ Alacritty${NC}"
    else
        echo -e "${RED}  ✗ Alacritty (not installed)${NC}"
        echo -e "${YELLOW}    Run: brew bundle --file=$DOTFILES_DIR/Brewfile${NC}"
    fi

    if [ -d "/Applications/AeroSpace.app" ]; then
        echo -e "${GREEN}  ✓ AeroSpace${NC}"
    else
        echo -e "${RED}  ✗ AeroSpace (not installed)${NC}"
        echo -e "${YELLOW}    Run: brew bundle --file=$DOTFILES_DIR/Brewfile.macos${NC}"
    fi

    if [ -d "/Applications/Hammerspoon.app" ]; then
        echo -e "${GREEN}  ✓ Hammerspoon${NC}"
    else
        echo -e "${RED}  ✗ Hammerspoon (not installed)${NC}"
        echo -e "${YELLOW}    Run: brew bundle --file=$DOTFILES_DIR/Brewfile.macos${NC}"
    fi

    if [ -d "/Applications/Raycast.app" ]; then
        echo -e "${GREEN}  ✓ Raycast${NC}"
        echo -e "${YELLOW}    Note: Raycast is optional and not in Brewfile.macos${NC}"
    else
        echo -e "${YELLOW}  ⚠ Raycast (optional - not installed)${NC}"
        echo -e "${YELLOW}    Install manually: brew install --cask raycast${NC}"
    fi

    # Check JetBrainsMono Nerd Font (macOS paths)
    if fc-list 2>/dev/null | grep -i "JetBrainsMono Nerd Font" > /dev/null || \
       ls ~/Library/Fonts/ 2>/dev/null | grep -i "JetBrainsMono" > /dev/null || \
       ls /Library/Fonts/ 2>/dev/null | grep -i "JetBrainsMono" > /dev/null; then
        echo -e "${GREEN}  ✓ JetBrainsMono Nerd Font${NC}"
    else
        echo -e "${RED}  ✗ JetBrainsMono Nerd Font (not installed)${NC}"
        echo -e "${YELLOW}    Run: brew bundle --file=$DOTFILES_DIR/Brewfile.macos${NC}"
    fi
elif [[ "$OS" == "Linux" ]]; then
    # Linux-specific checks
    check_command "alacritty" || echo -e "${YELLOW}    Install via package manager${NC}"

    # Check JetBrainsMono Nerd Font (Linux paths)
    if fc-list 2>/dev/null | grep -i "JetBrainsMono Nerd Font" > /dev/null || \
       ls ~/.local/share/fonts/ 2>/dev/null | grep -i "JetBrainsMono" > /dev/null || \
       ls /usr/share/fonts/ 2>/dev/null | grep -i "JetBrainsMono" > /dev/null; then
        echo -e "${GREEN}  ✓ JetBrainsMono Nerd Font${NC}"
    else
        echo -e "${RED}  ✗ JetBrainsMono Nerd Font (not installed)${NC}"
        echo -e "${YELLOW}    Download from: https://www.nerdfonts.com/${NC}"
    fi
else
    echo -e "${YELLOW}  ⚠ Unknown OS: $OS - skipping app-specific checks${NC}"
fi

echo ""
echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║     Installation Complete! 🎉         ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}Next steps:${NC}"
echo -e "  1. Restart your terminal or run: ${YELLOW}exec zsh${NC}"
echo -e "  2. If tools are missing, run: ${YELLOW}cd $DOTFILES_DIR && mise install${NC}"
if [[ "$OS" == "Darwin" ]]; then
echo -e "  3. If macOS apps are missing, run: ${YELLOW}brew bundle --file=$DOTFILES_DIR/Brewfile.macos${NC}"
echo -e "  4. Setup Raycast script commands (optional):"
else
echo -e "  3. Setup Raycast script commands (optional):"
fi
echo -e "     - Open Raycast Settings (⌘,)"
echo -e "     - Extensions → Script Commands"
echo -e "     - Add directory: ${YELLOW}$DOTFILES_DIR/raycast${NC}"
echo ""
echo -e "${BLUE}Configuration locations:${NC}"
echo -e "  mise:       $DOTFILES_DIR/.mise.toml"
if [[ "$OS" == "Darwin" ]]; then
echo -e "  Brewfile:   $DOTFILES_DIR/Brewfile.macos"
fi
echo -e "  Zsh:        ~/.zshrc"
echo -e "  tmux:       ~/.tmux.conf"
echo -e "  Neovim:     ~/.config/nvim"
echo -e "  Alacritty:  ~/.config/alacritty"
echo -e "  Claude:     ~/.claude/settings.json"
echo ""
