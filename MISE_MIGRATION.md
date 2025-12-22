# mise Migration Guide

**Summary:** Replaced Homebrew + fnm/pyenv/rbenv with mise for cross-platform portability and unified tool management.

## What Changed

### Before (Homebrew-centric)
```
Brewfile (77 packages) + fnm + pyenv + rbenv
├── Development runtimes via separate managers
├── CLI tools via Homebrew
├── GUI apps via Homebrew Casks
└── macOS-only
```

### After (mise-first)
```
.mise.toml (60+ tools) + Brewfile.macos (12 items)
├── Development runtimes via mise (replaces fnm/pyenv/rbenv)
├── CLI tools via mise
├── GUI apps via Homebrew (macOS only)
└── Cross-platform (Linux + macOS)
```

## Migration Details

### Replaced Package Managers

**Removed:**
- `fnm` (Fast Node Manager) → mise handles Node.js
- `pyenv` (Python version manager) → mise handles Python
- `rbenv` (Ruby version manager) → mise handles Ruby

**Benefits:**
- Single tool to manage all language runtimes
- Consistent interface across languages
- Cross-platform (works in Docker/Linux)

### Tools Migrated to mise

#### Development Runtimes
- `node` (replaces fnm)
- `python` (replaces pyenv)
- `ruby` (replaces rbenv)
- `java`, `php`, `scala`, `bun`, `deno`

#### CLI Tools (via cargo/npm)
- `eza`, `bat`, `fd`, `ripgrep`, `zoxide` (via cargo)
- `hyperfine`, `bottom` (btop alternative via cargo)
- `biome`, `coursier` (via npm)

#### Development Tools
- `yarn`, `maven`, `gradle`, `sbt`, `kubectl`, `jq`
- `git`, `gh`, `delta`, `tmux`, `neovim`, `fzf`

#### Code Quality
- `stylua`, `taplo`, `actionlint`, `shellcheck`

#### Utilities
- `sd`, `tokei` (cloc alternative), `du-dust`, `procs`
- `tealdeer` (tldr), `mkcert`, `direnv`, `watchexec`, `just`

#### Cloud/Infrastructure
- `terraform`, `awscli`

### Tools Remaining in Homebrew (macOS only)

**Brewfile.macos contains:**

**CLI Tools (macOS-specific):**
- `terminal-notifier` (macOS notifications API)
- `rsync`, `curl` (better versions than macOS defaults)
- `swiftlint` (Swift/iOS development)

**Fonts:**
- `font-jetbrains-mono-nerd-font`

**GUI Applications:**
- `aerospace` (window manager)
- `docker-desktop`
- `claude-code`
- `chromium`
- `homerow`

## Limitations

### What mise Cannot Install

1. **GUI Applications** - No support for `.app` bundles
   - Use Homebrew casks on macOS
   - Use system package managers on Linux

2. **macOS-specific tools** - Native APIs
   - `terminal-notifier` (macOS notifications)
   - `swiftlint` (Swift development)

3. **Fonts** - No font installation support
   - Use Homebrew on macOS: `brew install --cask font-*`
   - Manual installation on Linux

4. **Some specialized tools** - Not in mise registry
   - `tree-sitter` - Available via cargo but complex
   - Check availability: `mise registry` or https://mise.jdx.dev/registry.html

### Tool Availability Notes

**Cargo-based tools** (prefix `cargo:*`):
- Requires Rust toolchain (auto-installed by mise)
- First install is slower (compiles from source)
- Subsequent installs use binary cache

**NPM-based tools** (prefix `npm:*`):
- Requires Node.js (installed by mise)
- Fast installation

**Backend-specific limitations:**
- Some tools only available via specific backends
- Check: `mise registry <tool>` for availability

## Configuration Files

### .mise.toml Structure

```toml
[tools]
# Runtime versions
node = "lts"
python = "latest"

# Cargo tools
"cargo:eza" = "latest"

# NPM tools
"npm:@biomejs/biome" = "latest"

[env]
# Environment variables
EDITOR = "nvim"
_.path = ["$HOME/.local/bin"]

[settings]
# Auto-install on directory change
auto_install = true
# Read .node-version, .python-version, etc.
legacy_version_file = true
```

## Per-Project Version Switching

mise automatically switches tool versions when you cd into directories with version files.

### How it works

1. **Global defaults:** Set in `~/dotfiles/.mise.toml` (e.g., `node = "lts"`)
2. **Project-specific versions:** Specified via legacy version files (`.nvmrc`, `.python-version`, etc.)
3. **Auto-switching:** mise detects these files and activates the correct version on `cd`

### Example

```bash
# Global default (no version file in directory)
$ cd ~
$ node --version
v22.11.0  # LTS from .mise.toml

# Project-specific version (has .nvmrc)
$ cd ~/codebase/sf-ui-web
$ node --version
v24.10.0  # From .nvmrc file

# Another project (no version file)
$ cd ~/codebase/my-new-app
$ node --version
v22.11.0  # Back to LTS default

# Auto-install missing versions
$ cd ~/codebase/old-project  # Has .nvmrc: 18.0.0
mise: installing node@18.0.0...
$ node --version
v18.0.0  # Automatically installed and activated
```

### Supported Version Files

mise reads version files compatible with popular version managers:

**Node.js:**
- `.nvmrc` (nvm/fnm compatible)
- `.node-version` (fnm/nvm compatible)
- `.tool-versions` (asdf compatible)

**Python:**
- `.python-version` (pyenv compatible)
- `.tool-versions` (asdf compatible)

**Ruby:**
- `.ruby-version` (rbenv compatible)
- `.tool-versions` (asdf compatible)

**All tools:**
- `.tool-versions` (universal asdf format)

### Configuration Settings

These settings in `.mise.toml` enable auto-switching:

```toml
[settings]
# Enable reading of legacy version files
legacy_version_file = true  # Line 148 in .mise.toml

# Auto-install missing versions when switching
auto_install = true  # Line 151 in .mise.toml
```

### Migration from fnm/pyenv/rbenv

**Your existing projects don't need changes:**
- `.nvmrc` files work exactly as before (fnm → mise)
- `.python-version` files work exactly as before (pyenv → mise)
- `.ruby-version` files work exactly as before (rbenv → mise)

**Behavior comparison:**

| Tool | Old Behavior | New Behavior (mise) |
|------|--------------|---------------------|
| fnm  | `cd project && fnm use` (manual) | `cd project` (automatic) |
| pyenv | `cd project && pyenv local` (manual) | `cd project` (automatic) |
| rbenv | `cd project && rbenv local` (manual) | `cd project` (automatic) |

mise is **more automatic** than the old tools!

### Environment Variable Changes

**Added by mise:**
- `~/.local/share/mise/shims` - Tool shims (highest priority in PATH)
- `MISE_*` environment variables - mise configuration

**Removed:**
- `FNM_DIR`, `PYENV_ROOT`, `RBENV_ROOT` - No longer needed

## Shell Integration

### Zsh Configuration Updates

**Removed (obsolete):**
- `zsh/custom/03-lazy-load.zsh` - fnm/pyenv/rbenv lazy loading
- `zsh/custom/02-paths.zsh` - fnm PATH setup
- `zsh/custom/01-env.zsh` - PYENV_ROOT export

**Added:**
```zsh
# mise activation (in .zshrc)
eval "$(mise activate zsh)"
```

**mise handles:**
- PATH management (tool shims)
- Version detection (.tool-versions, .node-version, etc.)
- Auto-installation of missing tools

## Installation

### Fresh Installation

```bash
# 1. Install mise
curl https://mise.run | sh

# 2. Install all tools
cd ~/dotfiles
mise install

# 3. Install macOS-specific packages (if on macOS)
brew bundle --file=~/dotfiles/Brewfile.macos
```

### Docker Testing

```bash
# Test installation in clean Ubuntu environment
./test-install.sh
```

**What the test does:**
1. Builds Docker image with Ubuntu 24.04
2. Runs `install.sh` in container
3. Verifies symlinks and mise installation
4. No macOS-specific tools tested (Linux only)

### Updating Tools

```bash
# Update all mise tools
mise upgrade

# Update specific tool
mise upgrade node

# Update macOS packages
brew bundle --file=~/dotfiles/Brewfile.macos
```

## Common Commands

### mise Basics

```bash
# List installed tools
mise list

# List available tools
mise registry

# Install tool
mise use node@20

# Install from .mise.toml
mise install

# Activate mise in shell
eval "$(mise activate zsh)"

# Check mise status
mise doctor
```

### Version Management

```bash
# Global version (all projects)
mise use -g node@lts

# Project-local version
mise use node@20.1.0

# Check current versions
mise current
```

### Per-Project Tool Versions

mise supports legacy version files:

```
.node-version       # fnm/nvm compatible
.python-version     # pyenv compatible
.ruby-version       # rbenv compatible
.tool-versions      # asdf compatible
```

Or use project-local `.mise.toml`:

```toml
[tools]
node = "18.0.0"
python = "3.11"
```

## Troubleshooting

### mise not found after installation

```bash
# Add to PATH manually
export PATH="$HOME/.local/bin:$PATH"

# Or restart shell
exec zsh
```

### Tool installation fails

```bash
# Check mise status
mise doctor

# Try installing with verbose output
mise install -v

# Check specific tool availability
mise registry node
```

### Cargo tools fail to build

```bash
# Ensure build tools are installed
# macOS:
xcode-select --install

# Linux:
sudo apt-get install build-essential
```

### Legacy version files not working

```bash
# Check setting is enabled
mise settings

# Enable legacy version files
mise settings set legacy_version_file true
```

## Rollback Instructions

If you need to revert to Homebrew-only setup:

```bash
# 1. Restore original Brewfile
git checkout main -- Brewfile

# 2. Uninstall mise
rm -rf ~/.local/share/mise ~/.local/bin/mise ~/.config/mise

# 3. Install old package managers
brew install fnm pyenv rbenv

# 4. Reinstall tools
brew bundle --file=~/dotfiles/Brewfile

# 5. Restore zsh configs
git checkout main -- zsh/custom/
```

## Performance Comparison

**Initial Installation:**
- mise: ~5-10 minutes (compiles Rust tools from source)
- Homebrew: ~10-15 minutes (downloads pre-built binaries)

**Subsequent Installs:**
- mise: ~2-3 minutes (uses binary cache)
- Homebrew: ~3-5 minutes

**Runtime Performance:**
- Both are negligible (tools run natively)
- mise shims add <1ms overhead

## Resources

- mise documentation: https://mise.jdx.dev
- mise registry: https://mise.jdx.dev/registry.html
- GitHub: https://github.com/jdx/mise
- Configuration examples: https://mise.jdx.dev/configuration.html
