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

WITH_AGENTS=false

while [ $# -gt 0 ]; do
    case "$1" in
        --with-agents)
            WITH_AGENTS=true
            shift
            ;;
        *)
            echo "Unknown argument: $1" >&2
            exit 1
            ;;
    esac
done

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

install_tmux_plugins() {
    if ! command -v tmux > /dev/null 2>&1; then
        echo -e "${YELLOW}  ⚠ tmux not found, skipping tmux plugins${NC}"
        return 0
    fi

    if ! command -v git > /dev/null 2>&1; then
        echo -e "${YELLOW}  ⚠ git not found, skipping tmux plugins${NC}"
        return 0
    fi

    mkdir -p "$HOME/.tmux/plugins"

    if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
        echo -e "${YELLOW}  Installing Tmux Plugin Manager...${NC}"
        git clone --depth 1 https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
    else
        echo -e "${GREEN}  ✓ Tmux Plugin Manager already installed${NC}"
    fi

    if [ -x "$HOME/.tmux/plugins/tpm/bin/install_plugins" ]; then
        "$HOME/.tmux/plugins/tpm/bin/install_plugins" || echo -e "${YELLOW}  ⚠ Some tmux plugins failed to install${NC}"
    fi
}

font_installed() {
    command -v fc-list > /dev/null 2>&1 && fc-list 2>/dev/null | grep -qi "$1"
}

install_linux_nerd_fonts() {
    if ! command -v curl > /dev/null 2>&1 || ! command -v unzip > /dev/null 2>&1; then
        echo -e "${YELLOW}  ⚠ curl/unzip missing, skipping Linux font installation${NC}"
        return 0
    fi

    local font_dir="$HOME/.local/share/fonts"
    local tmp_dir
    tmp_dir="$(mktemp -d)"
    mkdir -p "$font_dir"

    local font_specs=(
        "JetBrainsMono|JetBrainsMono Nerd Font"
        "CascadiaCode|CaskaydiaCove Nerd Font"
        "SourceCodePro|SauceCodePro Nerd Font"
    )
    local installed_any=false
    local font_spec archive family zip_file url

    for font_spec in "${font_specs[@]}"; do
        archive="${font_spec%%|*}"
        family="${font_spec#*|}"

        if font_installed "$family"; then
            echo -e "${GREEN}  ✓ $family already installed${NC}"
            continue
        fi

        echo -e "${YELLOW}  Installing $family...${NC}"
        zip_file="$tmp_dir/$archive.zip"
        url="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/$archive.zip"

        if curl -fL "$url" -o "$zip_file" && unzip -oq "$zip_file" -d "$font_dir/$archive"; then
            echo -e "${GREEN}  ✓ $family installed${NC}"
            installed_any=true
        else
            echo -e "${YELLOW}  ⚠ Failed to install $family${NC}"
        fi
    done

    rm -rf "$tmp_dir"

    if [ "$installed_any" = true ]; then
        if command -v fc-cache > /dev/null 2>&1 && fc-cache -f "$font_dir"; then
            echo -e "${GREEN}  ✓ Font cache refreshed${NC}"
        else
            echo -e "${YELLOW}  ⚠ Failed to refresh font cache${NC}"
        fi
    fi
}

# Main installation steps
echo -e "${BLUE}[1/9] Installing mise (dev tools manager)...${NC}"

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

    # On macOS, install sdkman for Java (takes precedence over mise's java in zshrc)
    if [[ "$(uname -s)" == "Darwin" ]] && [ ! -d "$HOME/.sdkman" ]; then
        echo -e "${YELLOW}  Installing sdkman (Java version manager)...${NC}"
        curl -s "https://get.sdkman.io" | bash
        # Source sdkman for this session so scala can find java during mise install
        export SDKMAN_DIR="$HOME/.sdkman"
        [[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]] && source "$SDKMAN_DIR/bin/sdkman-init.sh"
        sdk install java
        echo -e "${GREEN}  ✓ sdkman + Java installed${NC}"
    fi

    # Install all tools
    echo -e "${YELLOW}  Installing tools...${NC}"
    mise install || echo -e "${YELLOW}  ⚠ Some tools failed to install, check output above${NC}"

    echo -e "${GREEN}  ✓ mise tools installed${NC}"
else
    echo -e "${YELLOW}  ⚠ .mise.toml not found, skipping tool installation${NC}"
fi

echo ""
echo -e "${BLUE}[2/9] Installing OS-specific packages...${NC}"

# Detect OS
OS="$(uname -s)"

if [[ "$OS" == "Darwin" ]]; then
    # macOS - install Homebrew packages
    if command -v brew &> /dev/null; then
        echo -e "${GREEN}  ✓ Homebrew detected${NC}"
        if [ -f "$DOTFILES_DIR/Brewfile.macos" ]; then
            echo -e "${YELLOW}  Installing macOS packages from Brewfile.macos...${NC}"
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
    # Linux - most CLI tools come from mise; install base system packages via apt.
    # zip/unzip are required by mise's java installer and asdf-style plugins;
    # build-essential/headers let mise compile runtimes (python, ruby) from source.
    if command -v apt-get &> /dev/null; then
        echo -e "${YELLOW}  Installing base packages via apt...${NC}"
        SUDO=""
        if [ "$(id -u)" -ne 0 ] && command -v sudo &> /dev/null; then
            SUDO="sudo"
        fi
        $SUDO apt-get update -y \
            || echo -e "${YELLOW}  ⚠ apt-get update failed, continuing...${NC}"
        $SUDO apt-get install -y \
            git curl build-essential fontconfig zip unzip lsof \
            zlib1g-dev libssl-dev libreadline-dev libyaml-dev libffi-dev \
            || echo -e "${YELLOW}  ⚠ Some apt packages failed, continuing...${NC}"
        echo -e "${GREEN}  ✓ Base packages processed${NC}"
    else
        echo -e "${YELLOW}  ⚠ apt-get not found — install git, curl, zip/unzip and build tools with your package manager${NC}"
    fi
    install_linux_nerd_fonts
    echo -e "${YELLOW}  Note: GUI apps (Ghostty/AeroSpace) and macOS notifiers are skipped on Linux${NC}"
    echo -e "${YELLOW}  CLI tools (incl. neovim, gh, delta, java) come from mise${NC}"
else
    echo -e "${YELLOW}  ⚠ Unknown OS: $OS - skipping system packages${NC}"
    echo -e "${YELLOW}  Most tools are installed via mise instead${NC}"
fi

echo ""
echo -e "${BLUE}[3/9] Installing ytfzf...${NC}"

# ytfzf - not in Homebrew, install via curl
if ! command -v ytfzf &> /dev/null; then
    echo -e "${YELLOW}  Installing ytfzf...${NC}"
    curl -sL https://raw.githubusercontent.com/pystardust/ytfzf/master/ytfzf -o "$HOME/.local/bin/ytfzf"
    chmod +x "$HOME/.local/bin/ytfzf"
    echo -e "${GREEN}  ✓ ytfzf installed${NC}"
else
    echo -e "${GREEN}  ✓ ytfzf already installed${NC}"
fi

echo ""
echo -e "${BLUE}[4/9] Initializing git submodules...${NC}"

if git -C "$DOTFILES_DIR" rev-parse --git-dir > /dev/null 2>&1; then
    echo -e "${YELLOW}  Updating git submodules...${NC}"
    git -C "$DOTFILES_DIR" submodule update --init --recursive
    echo -e "${GREEN}  ✓ Git submodules initialized${NC}"
else
    echo -e "${RED}  ✗ Not a git repository${NC}"
    echo -e "${YELLOW}  ⚠ Plugin submodules may not be initialized${NC}"
fi

echo ""
echo -e "${BLUE}[5/9] Setting up environment variables...${NC}"

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
echo -e "${BLUE}[6/9] Creating symlinks...${NC}"

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

# Claude Code
mkdir -p "$HOME/.claude"
substitute_json_template "$DOTFILES_DIR/claude/settings.json.template" "$HOME/.claude/settings.json"
create_symlink "$DOTFILES_DIR/claude/agents" "$HOME/.claude/agents"
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
create_symlink "$DOTFILES_DIR/pi/agent/extensions/mcp-buildkite" "$HOME/.pi/agent/extensions/mcp-buildkite"
create_symlink "$DOTFILES_DIR/pi/agent/extensions/web-tools.ts" "$HOME/.pi/agent/extensions/web-tools.ts"
create_symlink "$DOTFILES_DIR/pi/agent/extensions/theme-sync.ts" "$HOME/.pi/agent/extensions/theme-sync.ts"
create_symlink "$DOTFILES_DIR/pi/agent/extensions/media-manager.ts" "$HOME/.pi/agent/extensions/media-manager.ts"
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
echo -e "${BLUE}[7/9] Installing tmux plugins...${NC}"
install_tmux_plugins


echo ""
echo -e "${BLUE}[8/9] Making scripts executable...${NC}"

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

# Theme switching script (Ghostty + Neovim)
if [ -f "$DOTFILES_DIR/scripts/theme" ]; then
    chmod +x "$DOTFILES_DIR/scripts/theme"
    create_symlink "$DOTFILES_DIR/scripts/theme" "$HOME/.local/bin/theme"
    echo -e "${GREEN}  ✓ theme script linked${NC}"
fi


echo -e "${GREEN}  ✓ Scripts made executable${NC}"

echo ""
echo -e "${BLUE}[9/9] Verifying installation...${NC}"

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

    for font_name in "JetBrainsMono Nerd Font" "CaskaydiaCove Nerd Font" "SauceCodePro Nerd Font"; do
        if font_installed "$font_name"; then
            echo -e "${GREEN}  ✓ $font_name${NC}"
        else
            echo -e "${RED}  ✗ $font_name (not installed)${NC}"
            echo -e "${YELLOW}    Run: $DOTFILES_DIR/install.sh${NC}"
        fi
    done
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
