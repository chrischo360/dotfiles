# Dotfiles

Personal configuration files for macOS development environment.

## Repository Structure

```
~/dotfiles/
├── aerospace/          # AeroSpace window manager config
├── claude/             # Claude Code configuration and tools
│   ├── agents/         # Custom Claude Code agents
│   ├── ccstatusline/   # ccstatusline configuration
│   ├── hooks/          # Session hooks
│   │   ├── session/    # Session lifecycle (start, end, stop, user-input)
│   │   ├── tools/      # Tool tracking (pre/post tool use)
│   │   └── tracking/   # Metrics (tokens, costs, agents, buffers)
│   ├── scripts/        # Utilities
│   │   ├── state/      # Session state management
│   │   ├── cost/       # Cost tracking and analysis
│   │   ├── monitoring/ # CI/CD build monitoring
│   │   └── utils/      # Notifications, buffers, aliases
│   └── settings.json   # Claude Code settings
├── git/                # Git configuration
│   ├── gitconfig       # Global git config
│   └── hooks/          # Git hooks
├── nvim/               # Neovim configuration
├── raycast/            # Raycast script commands (CodeForces workflows)
├── tmux/               # tmux terminal multiplexer config
├── zsh/                # Zsh shell configuration
├── Brewfile            # Homebrew package dependencies
├── biome.json          # Biome code formatter config
├── stylua.toml         # Lua code formatter config
├── .env.example        # Environment variables template
└── .env                # Your API keys (gitignored, not committed)
```

## Environment Variables

API keys and secrets are stored in `.env` (gitignored, never committed).

**Setup:**
```bash
# Automatically created by install.sh
cp .env.example .env

# Edit with your API keys
vim ~/dotfiles/.env
```

**Variables:**
- `GITHUB_TOKEN` - GitHub personal access token (gh CLI, scout)
- `ANTHROPIC_API_KEY` - Claude API key
- `BUILDKITE_TOKEN` - Buildkite API token (CI monitoring)
- `GLEAN_API_TOKEN` - Glean API token (Wayfair knowledge base)
- `GLEAN_INSTANCE` - Glean instance name (default: wayfair)
- `GIT_AUTHOR_EMAIL` - Git user email (substituted into gitconfig)
- `GIT_AUTHOR_NAME` - Git user name (substituted into gitconfig)
- `RAYCAST_AUTHOR` - Raycast script author metadata

See `.env.example` for full list.

**Important:** The install script substitutes environment variables into `~/.gitconfig` from your `.env` file. Update `.env` with your git credentials before running the install script.

## Symlink Map

The install script creates these symlinks:

```
~/.zshrc                       -> ~/dotfiles/zsh/.zshrc
~/.tmux.conf                   -> ~/dotfiles/tmux/tmux.conf
~/.config/tmux/scripts/        -> ~/dotfiles/tmux/scripts/
~/.gitconfig                   -> ~/dotfiles/git/gitconfig (with env vars substituted)
~/.aerospace.toml              -> ~/dotfiles/aerospace/aerospace.toml
~/.hammerspoon/                -> ~/dotfiles/hammerspoon/
~/.config/alacritty/           -> ~/dotfiles/alacritty/
~/.config/nvim/                -> ~/dotfiles/nvim/
~/.config/ccstatusline/        -> ~/dotfiles/claude/ccstatusline/
~/.config/mise/config.toml     -> ~/dotfiles/.mise.toml (global mise config)
~/.claude/settings.json        -> ~/dotfiles/claude/settings.json (generated from template)
~/.claude/agents/              -> ~/dotfiles/claude/agents/
~/.claude/CLAUDE.md            -> ~/dotfiles/claude/CLAUDE.md
~/.gemini/settings.json        -> ~/dotfiles/gemini/settings.json (generated from template)
~/.local/bin/gemini            -> $(npm bin -g)/gemini
```

## Package Management

Uses **mise** for cross-platform dev tools + **Homebrew** (macOS only) for GUI apps.

**Why mise?**
- Cross-platform (macOS, Linux, Docker)
- Unified runtime management (replaces fnm, pyenv, rbenv)
- Fast, single binary
- Works in containers

See `MISE_MIGRATION.md` for migration details and limitations.

### Core Tools (from .mise.toml)

**Development Runtimes:**
- node (lts), python, ruby, java, php
- bun, deno, scala

**Terminal & Shell:**
- tmux, neovim, fzf
- zoxide, eza, bat, fd, ripgrep, bottom

**Version Control:**
- git, gh (GitHub CLI), delta

**Development Tools:**
- yarn, maven, gradle, sbt
- kubectl, jq, terraform, awscli

**Code Quality & Formatters:**
- biome, stylua, taplo, actionlint, shellcheck

**Utilities:**
- sd, tokei, du-dust, procs, tealdeer
- mkcert, direnv, watchexec, just
- pipx, cargo-binstall

**npm Global Packages:**
- ccstatusline - Claude Code statusline
- @google/gemini-cli - Gemini AI CLI (settings: ~/dotfiles/gemini/)

**Zsh Plugins (git submodules):**
- zsh-autosuggestions - Command suggestions
- fast-syntax-highlighting - Syntax highlighting

### macOS-Only Packages (from Brewfile.macos)

**CLI Tools:**
- terminal-notifier, rsync, curl, swiftlint

**Applications:**
- aerospace, docker-desktop, claude-code, chromium, homerow

**Fonts:**
- font-jetbrains-mono-nerd-font

**Optional:**
- Raycast (commented out)

## Installation

### Automatic Installation

```bash
cd ~/dotfiles
./install.sh
```

The install script will:
1. Install mise (dev tools manager)
2. Install tools from .mise.toml
3. Install macOS-specific packages from Brewfile.macos (if on macOS)
4. Initialize git submodules (zsh plugins)
5. Backup existing config files
6. Create all necessary symlinks
7. Make scripts executable
8. Verify installation and display summary

### Manual Installation

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
- **CLAUDE.md** - Global instructions and workflow rules
- **PAL_CONFIG.md** - PAL MCP Server configuration guide
- **agents/** - Custom agent definitions for specialized workflows
- **hooks/** - Session event handlers:
  - `session/` - Session lifecycle (session-start, session-end, claude-stop, user-input)
  - `tools/` - Tool tracking (pre-tool-use, post-tool-use)
  - `tracking/` - Metrics (track-tokens, log-session-cost, track-agent, inject-buffers)
- **scripts/** - Utility scripts:
  - `state/` - Session state management (update-session-state, debug-status)
  - `cost/` - Cost tracking and analysis (token-tracker, display-status, analyze-costs)
  - `monitoring/` - CI/CD build monitoring (monitor-buildkite, monitor-all-builds, etc.)
  - `utils/` - Notifications, buffers, aliases (notify, get-buffers, agent-stats)

See `claude/README.md` for detailed Claude Code documentation.

## Gemini CLI Directory

`~/dotfiles/gemini/` contains Gemini CLI configuration:

- **settings.json** - Gemini CLI config (auth type, editor, UI, MCP servers)

**Sensitive files** (gitignored, local in `~/.gemini/`):
- `google_accounts.json`, `mcp-oauth-tokens-v2.json` - Authentication
- `installation_id`, `state.json` - Session tracking

**Binary:** `~/.local/bin/gemini` → stable symlink to npm global

## PAL MCP Workflow

Claude automatically uses PAL tools for:
- **apilookup** - API/SDK docs, version info, breaking changes
- **clink** - Quick external model consultation
- **thinkdeep** - Deep investigation (gemini-3-pro-preview)
- **planner** - Implementation planning (gemini-3-pro-preview)
- **consensus** - Multi-model decisions (mixed pro/flash)
- **debug** - Systematic debugging (pro for complex, flash for simple)

Configuration: See `claude/PAL_CONFIG.md` for setup details.

## Usage Notes

### ccstatusline Configuration
Configure the statusline interactively:
```bash
ccstatusline
```

### Claude Session State Tracking

Multi-session awareness in tmux statusline. Tracks Claude Code sessions across panes.

**Display format:** `C: main📖✏️ work❓ dotfiles✅`
- 📖 Reading = Read, Glob (finding/reading files)
- 🔍 Searching = Grep (searching code)
- ✏️ Editing = Edit, Write (modifying files)
- ⚙️ Running = Bash (executing commands)
- 🤖 Delegating = Task (spawning agents)
- 🌐 Fetching = WebFetch, WebSearch (web requests)
- 🔄 Thinking = Generic active (processing, no specific tool)
- ❓ Question = AskUserQuestion (Claude asked a question)
- ✅ Ready = Idle (Claude finished, waiting for user input)
- Multiple icons = Multiple Claude sessions in that tmux session

**Quick reference:**
- State file: `~/.claude/session-state.json`
- Hooks configured in: `claude/settings.json`
- tmux statusline refreshes: Every 2 seconds
- Display format: `tmux-session-name + state-icons`

**See `claude/STATE_FLOW.md` for comprehensive documentation:**
- Complete hook execution order and timing
- State transition diagrams
- Edge cases and limitations (user interrupts, tool rejections, etc.)
- Testing and debugging procedures

**State transitions:**
- `SessionStart` → active (when session begins)
- `UserPromptSubmit` → active (when user sends input)
- `PreToolUse(AskUserQuestion)` → waiting_for_input (when Claude is about to ask a question)
- `Stop` → idle (when Claude finishes responding, unless already waiting)

**Quick debugging:**
```bash
# View current state and recent hook activity
~/dotfiles/claude/scripts/debug-status.sh

# Monitor hook execution in real-time
tail -f ~/.claude/hook-debug.log

# Manual state updates for testing
~/dotfiles/claude/scripts/update-session-state.sh <action>
# Actions: start, active, idle, waiting, stop
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

### Scout CLI (Browser Automation)

Scout is now a standalone npm package at `~/codebase/scout`.

**GitHub Commands:**
```bash
# Monitor CI/check status for a PR
scout watch-builds https://github.com/owner/repo/pull/123

# Auto-approve Dependabot PRs
scout auto-approve wayfair-shared/sf-ui-web

# Generate PR dashboard
scout pr-dashboard wayfair-shared/sf-ui-web

# Find PRs needing review
scout review-queue wayfair-shared/sf-ui-web
```

**Wayfair Commands:**
```bash
# Monitor Buildkite builds
scout buildkite-watch https://buildkite.com/wayfair/sf-ui-web-dev/builds/12345
```

**Setup:**
```bash
# One-time authentication setup
scout setup
```

**Configuration:**
User data stored in `~/.scout/`:
- `config.json` - Polling intervals, notifications, auto-approve settings
- `github-auth.json` - Browser authentication state (gitignored)

See [scout repository](~/codebase/scout) for development.

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
1. Clone repository with submodules: `git clone --recursive <your-repo-url> ~/dotfiles`
2. Run install script: `cd ~/dotfiles && ./install.sh`
3. Restart shell: `exec zsh`

The install script automatically installs:
- mise and all tools from .mise.toml
- macOS packages from Brewfile.macos (if on macOS)

### Managing Packages

**Add a new tool:**
```bash
# Add to .mise.toml manually, then:
cd ~/dotfiles
mise install

# Or install globally:
mise use -g <tool>@<version>
```

**Update tools:**
```bash
# Update all tools
mise upgrade

# Update specific tool
mise upgrade node
```

**macOS packages (Homebrew):**
```bash
# Add to Brewfile.macos, then:
brew bundle --file=~/dotfiles/Brewfile.macos
```

**Check tool availability:**
```bash
# Search mise registry
mise registry <tool-name>

# List installed tools
mise list
```

### Testing Installation (Docker)

Test the install script in a clean environment:

```bash
# Run full installation test
./test-install.sh
```

**What gets tested:**
- mise installation
- Tool installation from .mise.toml
- Symlink creation
- Configuration generation

**Note:** Docker test runs on Ubuntu, so macOS-specific packages are not tested.

### Troubleshooting
- If symlinks break, re-run the install script
- Check symlink status: `ls -la ~/.zshrc ~/.tmux.conf`
- Verify paths match your username in scripts
- mise not found: `export PATH="$HOME/.local/bin:$PATH"`
- Tool missing: `cd ~/dotfiles && mise install`

## Portability

### Path Configuration

**Centralized Paths:** All paths are managed through `config/paths.json`:
- `home` - User home directory
- `dotfiles` - Dotfiles repository location
- `codebase` - Development projects directory
- `local_bin` - Local binaries
- `pal_server` - PAL MCP server path

**Shell Scripts:** Use `$DOTFILES_DIR` environment variable
- Set automatically in `.zshrc` - no manual configuration needed
- Works regardless of where dotfiles repository is cloned
- Dynamically detected on shell startup

**JSON Configuration Files:** Generated from templates during install
- `claude/settings.json.template` → `~/.claude/settings.json`
- `gemini/settings.json.template` → `~/.gemini/settings.json`
- Templates use placeholders like `{{dotfiles}}`, `{{home}}`
- Generated files have absolute paths substituted during `install.sh`
- **Important:** Re-run `install.sh` if you move the dotfiles directory

**Neovim Lua Files:** Use `vim.fn.expand("~/")`
- Automatically expands tilde paths at runtime
- No manual configuration needed

### Cross-Platform Support

**OS Detection:** `install.sh` detects macOS vs Linux
- macOS: Checks `/Applications/*.app` for GUI apps
- Linux: Uses command-line tool checks
- Font paths adapted per platform

**Supported Platforms:**
- macOS (primary)
- Linux (basic support)

### API Keys and Secrets
All sensitive credentials are stored in `.env` (gitignored):
1. Copy `.env.example` to `.env`
2. Add your actual API keys
3. Never commit `.env` to version control

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
