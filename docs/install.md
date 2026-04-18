# Installation

## Automatic Installation

```bash
cd ~/dotfiles
./install.sh
```

The install script will:
1. Install mise (dev tools manager)
2. Install tools from .mise.toml (all CLI tools and runtimes)
3. Install macOS-specific packages from Brewfile.macos (if on macOS)
4. Initialize git submodules (zsh plugins)
5. Backup existing config files
6. Create all necessary symlinks
7. Make scripts executable
8. Verify installation and display summary

## Manual Installation

1. **Clone the repository (with submodules):**
   ```bash
   git clone --recursive <your-repo-url> ~/dotfiles
   cd ~/dotfiles
   ```

2. **Install mise:**
   ```bash
   curl https://mise.run | sh
   export PATH="$HOME/.local/bin:$PATH"
   ```

3. **Install tools from .mise.toml:**
   ```bash
   cd ~/dotfiles
   mise install
   ```

4. **Install macOS-specific packages (if on macOS):**
   ```bash
   brew bundle --file=~/dotfiles/Brewfile.macos
   ```

5. **Initialize git submodules (if not cloned with --recursive):**
   ```bash
   git submodule update --init --recursive
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
   mkdir -p ~/.config

   ln -sf ~/dotfiles/ghostty ~/.config/ghostty
   ln -sf ~/dotfiles/kitty ~/.config/kitty
   ln -sf ~/dotfiles/nvim ~/.config/nvim
   ln -sf ~/dotfiles/ccstatusline ~/.config/ccstatusline

   mkdir -p ~/.config/mise
   ln -sf ~/dotfiles/.mise.toml ~/.config/mise/config.toml

   mkdir -p ~/.claude
   ln -sf ~/dotfiles/claude/settings.json ~/.claude/settings.json
   ln -sf ~/dotfiles/claude/agents ~/.claude/agents
   ```

7. **Make scripts executable:**
   ```bash
   chmod +x ~/dotfiles/claude/scripts/*.sh
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

## Moving to a New Computer

1. Clone repository with submodules: `git clone --recursive <your-repo-url> ~/dotfiles`
2. Run install script: `cd ~/dotfiles && ./install.sh`
3. Restart shell: `exec zsh`

The install script automatically installs mise and all tools from `.mise.toml`, plus macOS packages from `Brewfile.macos` if on macOS.

## Testing Installation (Docker)

Test the install script in a clean environment:

```bash
./test-install.sh
```

What gets tested:
- mise installation
- Tool installation from .mise.toml
- Symlink creation
- Configuration generation

Note: Docker test runs on Ubuntu, so macOS-specific packages are not tested.
