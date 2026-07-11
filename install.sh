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
    # Create parent directory if needed
    mkdir -p "$(dirname "$output")"

    # Substitute placeholders
    sed -e "s|{{home}}|$home|g" \
        -e "s|{{dotfiles}}|$dotfiles|g" \
        -e "s|{{codebase}}|$codebase|g" \
        -e "s|{{local_bin}}|$local_bin|g" \
        "$template" > "$output"

    echo -e "${GREEN}  ✓ Generated: $output${NC}"
}

# Main installation steps
echo -e "${BLUE}[1/6] Installing mise (dev tools manager)...${NC}"

# Install mise if not present
if ! command -v mise &> /dev/null; then
    echo -e "${YELLOW}  Installing mise...${NC}"
    curl -fsSL https://mise.run | sh || echo -e "${YELLOW}  ⚠ mise install script failed, continuing...${NC}"

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
        # Don't let a malformed line in .env (e.g. an unquoted value with spaces)
        # abort the whole install via `set -e`.
        set +e
        set -a
        source "$DOTFILES_DIR/.env" 2>/dev/null
        set +a
        set -e
        # Only pass GITHUB_TOKEN to mise's aqua backend if it looks like a real
        # token. A placeholder/expired token causes 401s; an unset token lets the
        # backend fetch anonymously (rate-limited but works for public tools).
        # Real tokens are a prefix + alphanumerics (the .env.example placeholder
        # contains underscores/words, so it won't match).
        if [[ "$GITHUB_TOKEN" =~ ^(ghp_|github_pat_|gho_|ghu_)[A-Za-z0-9_]{20,}$ && "$GITHUB_TOKEN" != *your_* ]]; then
            export AQUA_GITHUB_TOKEN="${GITHUB_TOKEN}"
        else
            echo -e "${YELLOW}  ⚠ GITHUB_TOKEN not set (or still a placeholder) — using anonymous GitHub access${NC}"
            unset AQUA_GITHUB_TOKEN GITHUB_TOKEN
        fi
    else
        echo -e "${YELLOW}  ⚠ .env not found, aqua backend may hit GitHub API rate limits${NC}"
    fi

    # Change to dotfiles directory so mise picks up .mise.toml
    cd "$DOTFILES_DIR"

    # Recent mise versions refuse to use a config until it's trusted.
    # Trust both the repo config and the global symlinked config.
    mise trust "$DOTFILES_DIR/.mise.toml" 2>/dev/null || true
    mise trust "$HOME/.config/mise/config.toml" 2>/dev/null || true

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
echo -e "${BLUE}[2/6] Installing OS-specific packages...${NC}"

# Detect OS
OS="$(uname -s)"

if [[ "$OS" == "Darwin" ]]; then
    # macOS - install Homebrew packages
    if command -v brew &> /dev/null; then
        echo -e "${GREEN}  ✓ Homebrew detected${NC}"
        if [ -f "$DOTFILES_DIR/Brewfile.macos" ]; then
            echo -e "${YELLOW}  Installing macOS packages from Brewfile.macos...${NC}"
            # Don't let a single failing formula abort the whole install
            brew bundle --file="$DOTFILES_DIR/Brewfile.macos" \
                || echo -e "${YELLOW}  ⚠ Some Homebrew packages failed, continuing...${NC}"
            echo -e "${GREEN}  ✓ macOS packages processed${NC}"
        else
            echo -e "${YELLOW}  ⚠ Brewfile.macos not found, skipping package installation${NC}"
        fi
    else
        echo -e "${RED}  ✗ Homebrew not installed${NC}"
        echo -e "${YELLOW}  Install Homebrew first: /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\"${NC}"
        echo -e "${YELLOW}  Then re-run this script to install macOS packages${NC}"
    fi
elif [[ "$OS" == "Linux" ]]; then
    # Linux - most CLI tools come from mise; install base system packages via apt
    if command -v apt-get &> /dev/null; then
        echo -e "${YELLOW}  Installing base packages via apt...${NC}"
        SUDO=""
        if [ "$(id -u)" -ne 0 ] && command -v sudo &> /dev/null; then
            SUDO="sudo"
        fi
        $SUDO apt-get update -y \
            || echo -e "${YELLOW}  ⚠ apt-get update failed, continuing...${NC}"
        # build-essential/headers let mise compile runtimes (python, ruby) from source
        $SUDO apt-get install -y \
            git curl build-essential fontconfig \
            zlib1g-dev libssl-dev libreadline-dev libyaml-dev libffi-dev \
            || echo -e "${YELLOW}  ⚠ Some apt packages failed, continuing...${NC}"
        echo -e "${GREEN}  ✓ Base packages processed${NC}"
    else
        echo -e "${YELLOW}  ⚠ apt-get not found — install git, curl and build tools with your package manager${NC}"
    fi
    echo -e "${YELLOW}  Note: GUI apps (Ghostty/AeroSpace) and macOS notifiers are skipped on Linux${NC}"
    echo -e "${YELLOW}  CLI tools (incl. neovim, gh, delta) come from mise${NC}"
else
    echo -e "${YELLOW}  ⚠ Unknown OS: $OS - skipping system packages${NC}"
    echo -e "${YELLOW}  Most tools are installed via mise instead${NC}"
fi

echo ""
echo -e "${BLUE}[2b/6] Installing ytfzf...${NC}"

# ytfzf - not in any package registry, install via curl
if ! command -v ytfzf &> /dev/null; then
    echo -e "${YELLOW}  Installing ytfzf...${NC}"
    mkdir -p "$HOME/.local/bin"
    # -f makes curl fail on HTTP errors instead of writing an error page to the file
    if curl -fsSL https://raw.githubusercontent.com/pystardust/ytfzf/master/ytfzf -o "$HOME/.local/bin/ytfzf"; then
        chmod +x "$HOME/.local/bin/ytfzf"
        echo -e "${GREEN}  ✓ ytfzf installed${NC}"
    else
        rm -f "$HOME/.local/bin/ytfzf"
        echo -e "${YELLOW}  ⚠ ytfzf download failed, skipping${NC}"
    fi
else
    echo -e "${GREEN}  ✓ ytfzf already installed${NC}"
fi

echo ""
echo -e "${BLUE}[3/6] Initializing git submodules...${NC}"

if git -C "$DOTFILES_DIR" rev-parse --git-dir > /dev/null 2>&1; then
    echo -e "${YELLOW}  Updating git submodules...${NC}"
    git -C "$DOTFILES_DIR" submodule update --init --recursive \
        || echo -e "${YELLOW}  ⚠ Some submodules failed to initialize, continuing...${NC}"
    echo -e "${GREEN}  ✓ Git submodules processed${NC}"
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

# Buildkite
create_symlink "$DOTFILES_DIR/buildkite/.bk.yaml" "$HOME/.bk.yaml"

# Zsh
create_symlink "$DOTFILES_DIR/zsh/.zshrc" "$HOME/.zshrc"

# tmux
create_symlink "$DOTFILES_DIR/tmux/tmux.conf" "$HOME/.tmux.conf"
create_symlink "$DOTFILES_DIR/tmux/scripts" "$HOME/.config/tmux/scripts"

# Git
create_symlink "$DOTFILES_DIR/git/gitconfig" "$HOME/.gitconfig"

# AeroSpace
create_symlink "$DOTFILES_DIR/aerospace/aerospace.toml" "$HOME/.aerospace.toml"

# Create ~/.config directory
mkdir -p "$HOME/.config"

# Terminal emulators
create_symlink "$DOTFILES_DIR/ghostty" "$HOME/.config/ghostty"

# Neovim
create_symlink "$DOTFILES_DIR/nvim" "$HOME/.config/nvim"

# ccstatusline
create_symlink "$DOTFILES_DIR/claude/ccstatusline" "$HOME/.config/ccstatusline"

# mise global config (makes tools available everywhere)
mkdir -p "$HOME/.config/mise"
create_symlink "$DOTFILES_DIR/.mise.toml" "$HOME/.config/mise/config.toml"
# .mise.toml references a shorthands file — create an empty one if missing so mise doesn't warn
[ -f "$HOME/.config/mise/shorthands.toml" ] || touch "$HOME/.config/mise/shorthands.toml"

# Claude Code
mkdir -p "$HOME/.claude"
substitute_json_template "$DOTFILES_DIR/claude/settings.json.template" "$HOME/.claude/settings.json"
create_symlink "$DOTFILES_DIR/claude/commands" "$HOME/.claude/commands"
create_symlink "$DOTFILES_DIR/claude/AGENTS.md" "$HOME/.claude/AGENTS.md"

# Pi Coding Agent
mkdir -p "$HOME/.pi/agent/extensions"
create_symlink "$DOTFILES_DIR/pi/agent/settings.json" "$HOME/.pi/agent/settings.json"
create_symlink "$DOTFILES_DIR/pi/agent/AGENTS.md" "$HOME/.pi/agent/AGENTS.md"
create_symlink "$DOTFILES_DIR/pi/agent/keybindings.json" "$HOME/.pi/agent/keybindings.json"
create_symlink "$DOTFILES_DIR/pi/agent/extensions/anthropic-vertex" "$HOME/.pi/agent/extensions/anthropic-vertex"
create_symlink "$DOTFILES_DIR/pi/agent/extensions/plan-mode" "$HOME/.pi/agent/extensions/plan-mode"
create_symlink "$DOTFILES_DIR/pi/agent/extensions/session-status.ts" "$HOME/.pi/agent/extensions/session-status.ts"
create_symlink "$DOTFILES_DIR/pi/agent/extensions/protected-paths.ts" "$HOME/.pi/agent/extensions/protected-paths.ts"
create_symlink "$DOTFILES_DIR/pi/agent/extensions/mcp-sourcegraph" "$HOME/.pi/agent/extensions/mcp-sourcegraph"
create_symlink "$DOTFILES_DIR/pi/agent/extensions/mcp-glean" "$HOME/.pi/agent/extensions/mcp-glean"
create_symlink "$DOTFILES_DIR/pi/agent/extensions/mcp-github" "$HOME/.pi/agent/extensions/mcp-github"
create_symlink "$DOTFILES_DIR/pi/agent/extensions/web-tools.ts" "$HOME/.pi/agent/extensions/web-tools.ts"
create_symlink "$DOTFILES_DIR/pi/agent/extensions/theme-sync.ts" "$HOME/.pi/agent/extensions/theme-sync.ts"
create_symlink "$DOTFILES_DIR/pi/agent/themes" "$HOME/.pi/agent/themes"
create_symlink "$DOTFILES_DIR/agent/commands" "$HOME/.pi/agent/prompts"

# Shared agent skills
mkdir -p "$HOME/.agents/skills"
for skill_dir in "$DOTFILES_DIR/agent/skills"/*/; do
  [ -d "$skill_dir" ] || continue
  create_symlink "$skill_dir" "$HOME/.agents/skills/$(basename "$skill_dir")"
done

# Pi repo-specific prompts — symlink claude commands into each codebase repo
for repo_dir in "$DOTFILES_DIR/claude/commands/repos"/*/; do
  repo_name=$(basename "$repo_dir")
  repo_path="$HOME/codebase/$repo_name"
  if [ -d "$repo_path" ]; then
    mkdir -p "$repo_path/.pi/prompts"
    for f in "$repo_dir"*.md; do
      [ -f "$f" ] || continue
      create_symlink "$f" "$repo_path/.pi/prompts/$(basename "$f")"
    done
  fi
done


echo ""
echo -e "${BLUE}[6/6] Making scripts executable...${NC}"

# Make all shell scripts executable
find "$DOTFILES_DIR/claude/scripts" -type f -name "*.sh" -exec chmod +x {} \;
find "$DOTFILES_DIR/claude/hooks" -type f -name "*.sh" -exec chmod +x {} \;
find "$DOTFILES_DIR/tmux/scripts" -name "*.sh" -exec chmod +x {} \;
chmod +x "$DOTFILES_DIR/claude/status"

# Ghostty font switching script
if [ -f "$DOTFILES_DIR/scripts/ghostty-font" ]; then
    chmod +x "$DOTFILES_DIR/scripts/ghostty-font"
    create_symlink "$DOTFILES_DIR/scripts/ghostty-font" "$HOME/.local/bin/ghostty-font"
    echo -e "${GREEN}  ✓ ghostty-font script linked${NC}"
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
else
    check_command "noti" || echo -e "${YELLOW}    Install noti for agent notifications: https://github.com/variadico/noti${NC}"
fi

# Platform-specific application checks
if [[ "$OS" == "Darwin" ]]; then
    # macOS-specific checks
    if [ -d "/Applications/Ghostty.app" ]; then
        echo -e "${GREEN}  ✓ Ghostty${NC}"
    else
        echo -e "${RED}  ✗ Ghostty (not installed)${NC}"
        echo -e "${YELLOW}    Run: brew bundle --file=$DOTFILES_DIR/Brewfile.macos${NC}"
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
    check_command "ghostty" || echo -e "${YELLOW}  ⚠ Ghostty (install via package manager)${NC}"

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
fi
echo ""
echo -e "${BLUE}Configuration locations:${NC}"
echo -e "  mise:       $DOTFILES_DIR/.mise.toml"
if [[ "$OS" == "Darwin" ]]; then
echo -e "  Brewfile:   $DOTFILES_DIR/Brewfile.macos"
fi
echo -e "  Zsh:        ~/.zshrc"
echo -e "  tmux:       ~/.tmux.conf"
echo -e "  Neovim:     ~/.config/nvim"
echo -e "  Ghostty:    ~/.config/ghostty"
echo -e "  Claude:     ~/.claude/settings.json"
echo ""
