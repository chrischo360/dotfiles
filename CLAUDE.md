# Dotfiles

Personal configuration files for macOS development environment.

## Repository Structure

```
~/dotfiles/
├── aerospace/          # AeroSpace window manager config
├── alacritty/          # Alacritty terminal emulator
│   ├── scripts/        # Theme switching and management
│   └── themes/         # Color scheme collection
├── claude/             # Claude Code configuration and tools
│   ├── agents/         # Custom Claude Code agents
│   ├── hooks/          # Session hooks (token tracking, cost logging)
│   ├── scripts/        # Utilities (statusline, notifications, monitoring)
│   └── settings.json   # Claude Code settings
├── hammerspoon/        # Hammerspoon automation (Slack keyboard navigation)
├── nvim/               # Neovim configuration
├── raycast/            # Raycast script commands (CodeForces workflows)
├── starship/           # Starship prompt configuration
├── tmux/               # tmux terminal multiplexer config
├── zsh/                # Zsh shell configuration
├── biome.json          # Biome code formatter config
└── stylua.toml         # Lua code formatter config
```

## Symlink Map

The install script creates these symlinks:

```
~/.zshrc                  -> ~/dotfiles/zsh/.zshrc
~/.tmux.conf              -> ~/dotfiles/tmux/tmux.conf
~/.aerospace.toml         -> ~/dotfiles/aerospace/aerospace.toml
~/.hammerspoon/           -> ~/dotfiles/hammerspoon/
~/.config/alacritty/      -> ~/dotfiles/alacritty/
~/.config/nvim/           -> ~/dotfiles/nvim/
~/.config/starship.toml   -> ~/dotfiles/starship/starship.toml
~/.claude/settings.json   -> ~/dotfiles/claude/settings.json
~/.claude/statusline.sh   -> ~/dotfiles/claude/scripts/statusline.sh
~/.claude/agents/         -> ~/dotfiles/claude/agents/
~/.claude/CLAUDE.md       -> ~/dotfiles/claude/CLAUDE.md
```

## Required Packages

### Core Tools
- **Homebrew** - macOS package manager
- **Git** - Version control

### Terminal & Shell
- **Alacritty** - GPU-accelerated terminal emulator
- **tmux** - Terminal multiplexer
- **Zsh** - Shell (macOS default)
- **Oh My Zsh** - Zsh framework
- **Starship** - Cross-shell prompt

### Fonts
- **JetBrainsMono Nerd Font** - Terminal font with icons

### Window Management
- **AeroSpace** - Tiling window manager
- **Hammerspoon** - macOS automation

### Utilities
- **Raycast** - Launcher and productivity tool
- **terminal-notifier** - macOS notifications
- **bc** - Calculator (for Claude cost tracking)

### Development
- **Neovim** - Text editor
- **Node.js** / **nvm** - JavaScript runtime
- **Python** / **pyenv** - Python version manager
- **PHP** - PHP interpreter
- **Composer** - PHP package manager
- **Rust** / **cargo** - Rust toolchain
- **Docker** - Containerization

### Optional
- **zoxide** - Smarter cd command
- **zsh-autosuggestions** - Fish-like autosuggestions
- **zsh-syntax-highlighting** - Command syntax highlighting

## Installation

### Automatic Installation

```bash
cd ~/dotfiles
./install.sh
```

The install script will:
1. Backup existing config files
2. Create all necessary symlinks
3. Install Oh My Zsh plugins
4. Make scripts executable
5. Display installation summary

### Manual Installation

1. **Clone the repository:**
   ```bash
   git clone <your-repo-url> ~/dotfiles
   cd ~/dotfiles
   ```

2. **Install Homebrew packages:**
   ```bash
   brew install --cask alacritty
   brew install tmux neovim
   brew install starship
   brew install terminal-notifier
   brew install font-jetbrains-mono-nerd-font
   brew install --cask aerospace
   brew install --cask hammerspoon
   brew install --cask raycast
   ```

3. **Install Oh My Zsh:**
   ```bash
   sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
   ```

4. **Install Zsh plugins:**
   ```bash
   git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
   git clone https://github.com/zsh-users/zsh-syntax-highlighting ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
   ```

5. **Install development tools:**
   ```bash
   # NVM (Node Version Manager)
   curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash

   # Pyenv
   brew install pyenv

   # Rust
   curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
   ```

6. **Create symlinks:**
   ```bash
   # Backup existing configs
   mv ~/.zshrc ~/.zshrc.backup 2>/dev/null
   mv ~/.tmux.conf ~/.tmux.conf.backup 2>/dev/null

   # Create symlinks
   ln -sf ~/dotfiles/zsh/.zshrc ~/.zshrc
   ln -sf ~/dotfiles/tmux/tmux.conf ~/.tmux.conf
   ln -sf ~/dotfiles/aerospace/aerospace.toml ~/.aerospace.toml
   ln -sf ~/dotfiles/hammerspoon ~/.hammerspoon

   # Create .config directory if needed
   mkdir -p ~/.config

   ln -sf ~/dotfiles/alacritty ~/.config/alacritty
   ln -sf ~/dotfiles/nvim ~/.config/nvim
   ln -sf ~/dotfiles/starship/starship.toml ~/.config/starship.toml

   # Claude Code configs
   mkdir -p ~/.claude
   ln -sf ~/dotfiles/claude/settings.json ~/.claude/settings.json
   ln -sf ~/dotfiles/claude/scripts/statusline.sh ~/.claude/statusline.sh
   ln -sf ~/dotfiles/claude/agents ~/.claude/agents
   ```

7. **Make scripts executable:**
   ```bash
   chmod +x ~/dotfiles/claude/scripts/*.sh
   chmod +x ~/dotfiles/alacritty/scripts/*.sh
   chmod +x ~/dotfiles/raycast/*.sh
   chmod +x ~/dotfiles/tmux/scripts/*.sh
   ```

8. **Setup Raycast scripts:**
   - Open Raycast Settings (⌘,)
   - Go to Extensions → Script Commands
   - Add Script Directory: `~/dotfiles/raycast`

9. **Restart your shell:**
   ```bash
   exec zsh
   ```

## Claude Code Directory

The `~/dotfiles/claude/` directory contains Claude Code configuration and utilities:

- **settings.json** - Main Claude Code configuration (permissions, model, hooks, statusline)
- **agents/** - Custom agent definitions for specialized workflows
- **hooks/** - Session hooks for token tracking and cost logging
- **scripts/** - Utility scripts:
  - `statusline.sh` - Real-time token usage display
  - `notify.sh` - macOS notification integration
  - `token-tracker.sh` - Cost calculation utilities
  - `monitor-buildkite.sh` - CI/CD build monitoring
  - `display-status.sh` - Token/cost status display

See `claude/README.md` for detailed Claude Code documentation.

## Usage Notes

### Alacritty Theme Switching
Use the theme picker alias:
```bash
at  # Opens theme selection menu
```

### Claude Code Status
Check token usage and costs:
```bash
~/dotfiles/claude/status [tokens] [model]
```

### Raycast CodeForces Commands
- `CF Next Problem` - Find next unsolved problem
- `CF Add Progress` - Log completed problem
- `CF Show Progress` - View training stats

## Maintenance

### Updating Configurations
All configs are version-controlled. After making changes:
```bash
cd ~/dotfiles
git add .
git commit -m "Update configuration"
git push
```

### Moving to a New Computer
1. Clone this repository
2. Run `./install.sh`
3. Install required packages via Homebrew
4. Restart shell

### Troubleshooting
- If symlinks break, re-run the install script
- Check symlink status: `ls -la ~/.zshrc ~/.tmux.conf`
- Verify paths match your username in scripts
