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
│   ├── scripts/        # Utilities (notifications, monitoring)
│   └── settings.json   # Claude Code settings
├── ccstatusline/       # ccstatusline configuration
├── hammerspoon/        # Hammerspoon automation (Slack keyboard navigation)
├── nvim/               # Neovim configuration
├── raycast/            # Raycast script commands (CodeForces workflows)
├── tmux/               # tmux terminal multiplexer config
├── zsh/                # Zsh shell configuration
├── Brewfile            # Homebrew package dependencies
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
~/.config/ccstatusline/   -> ~/dotfiles/ccstatusline/
~/.claude/settings.json   -> ~/dotfiles/claude/settings.json
~/.claude/agents/         -> ~/dotfiles/claude/agents/
~/.claude/CLAUDE.md       -> ~/dotfiles/claude/CLAUDE.md
```

## Package Management

All Homebrew dependencies are managed via **Brewfile**. The install script automatically installs packages from the Brewfile.

### Core Packages (from Brewfile)

**Terminal & Shell:**
- tmux, neovim, zsh
- zoxide, eza, bat, fd, fzf, ripgrep, btop

**Development Tools:**
- node (includes npm), php@8.1, composer, biome

**npm Global Packages:**
- ccstatusline - Claude Code statusline

**Applications:**
- alacritty, aerospace, hammerspoon, docker

**Fonts:**
- font-jetbrains-mono-nerd-font

**Utilities:**
- terminal-notifier, cloc

### Manual Setup Required

**Oh My Zsh & Plugins:**
- Oh My Zsh framework (installed by install.sh)
- zsh-autosuggestions plugin (installed by install.sh)
- zsh-syntax-highlighting plugin (installed by install.sh)

**Optional Tools:**
- **Raycast** - Launcher (commented out in Brewfile)
- **NVM** - Node version manager
- **Pyenv** - Python version manager
- **Rust** - Install via rustup

## Installation

### Automatic Installation

```bash
cd ~/dotfiles
./install.sh
```

The install script will:
1. Install Homebrew packages from Brewfile
2. Backup existing config files
3. Create all necessary symlinks
4. Make scripts executable
5. Install Oh My Zsh plugins
6. Verify installation and display summary

### Manual Installation

1. **Clone the repository:**
   ```bash
   git clone <your-repo-url> ~/dotfiles
   cd ~/dotfiles
   ```

2. **Install Homebrew packages:**
   ```bash
   # Install all packages from Brewfile
   brew bundle --file=~/dotfiles/Brewfile
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

5. **Install optional development tools:**
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
   ln -sf ~/dotfiles/ccstatusline ~/.config/ccstatusline

   # Claude Code configs
   mkdir -p ~/.claude
   ln -sf ~/dotfiles/claude/settings.json ~/.claude/settings.json
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
  - `notify.sh` - macOS notification integration
  - `token-tracker.sh` - Cost calculation utilities
  - `monitor-buildkite.sh` - CI/CD build monitoring
  - `display-status.sh` - Token/cost status display

See `claude/README.md` for detailed Claude Code documentation.

## Usage Notes

### ccstatusline Configuration
Configure the statusline interactively:
```bash
ccstatusline
```

### Alacritty Theme Switching
Use the theme picker alias:
```bash
at  # Opens theme selection menu
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
1. Install Homebrew: `/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"`
2. Clone this repository: `git clone <your-repo-url> ~/dotfiles`
3. Run install script: `cd ~/dotfiles && ./install.sh`
4. Restart shell: `exec zsh`

The install script will automatically install all packages from the Brewfile.

### Managing Packages

**Add a new package:**
```bash
# Add to Brewfile manually, then run:
brew bundle --file=~/dotfiles/Brewfile
```

**Update Brewfile from current installation:**
```bash
brew bundle dump --file=~/dotfiles/Brewfile --force
```

**Check what would be installed:**
```bash
brew bundle check --file=~/dotfiles/Brewfile
```

### Troubleshooting
- If symlinks break, re-run the install script
- Check symlink status: `ls -la ~/.zshrc ~/.tmux.conf`
- Verify paths match your username in scripts

## Instructions for Claude Code

When working in this dotfiles repository, follow these synchronization rules:

### Adding New Shell Tools or Aliases

**When adding new shell functions or aliases that depend on external tools:**

1. **Check if the tool is in Brewfile**
   - Read `Brewfile` to verify the dependency exists
   - Example: Adding `nvimgrep` function that uses `ripgrep`

2. **Add missing tools to Brewfile**
   - Add the tool to the appropriate section (Shell Enhancements, Development Tools, etc.)
   - Use format: `brew "tool-name"   # Brief description`
   - Example: `brew "ripgrep"   # Fast text search (rg)`

3. **Update CLAUDE.md documentation**
   - Update "Core Packages (from Brewfile)" section (~line 49)
   - Add the new tool to the relevant category
   - Keep the list synchronized with actual Brewfile contents

4. **Update function/alias comments**
   - Ensure zsh functions have clear comments about their dependencies
   - Example: `# Search file contents with ripgrep and open in neovim`

### Keeping Documentation in Sync

**When modifying any configuration files:**

- If you add/remove tools from Brewfile → update CLAUDE.md "Core Packages" section
- If you add/remove shell aliases → update CLAUDE.md if they're user-facing features
- If you add/remove symlinks → update CLAUDE.md "Symlink Map" section
- If you add new scripts → update relevant "Usage Notes" or directory descriptions

### Example Workflow

```
User: "Add a new fzf function for searching files"
Claude:
  1. Create the function in zsh/custom/05-aliases.zsh
  2. Check: Does it use fzf? → Read Brewfile
  3. If fzf is missing → Add to Brewfile in Shell Enhancements
  4. Update CLAUDE.md Core Packages section to include fzf
  5. Commit changes: both code AND documentation together
```

**Key principle:** Keep Brewfile, zsh configs, and CLAUDE.md synchronized at all times.
