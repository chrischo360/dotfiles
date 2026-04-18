# Dotfiles

Personal configuration files for macOS development environment.

## Repository Structure

```
~/dotfiles/
├── aerospace/          # AeroSpace window manager config
├── biome/              # Biome JS/TS formatter config
├── buildkite/          # Buildkite CLI config
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
├── cursor/             # Cursor AI editor configuration
├── git/                # Git configuration
├── ghostty/            # Ghostty terminal emulator config
├── kitty/              # Kitty terminal emulator config
├── lua/                # Lua tooling config (stylua)
├── nvim/               # Neovim configuration
├── pi/                 # Pi coding agent configuration
├── raycast/            # Raycast script commands
├── tests/              # Docker-based install test suite
├── tmux/               # tmux terminal multiplexer config
├── zsh/                # Zsh shell configuration
├── docs/               # Documentation
│   ├── install.md      # Installation guide
│   ├── maintenance.md  # Maintenance and package management
│   ├── portability.md  # Path config and cross-platform notes
│   └── tools/          # Per-tool reference docs
├── Brewfile.macos      # Homebrew package dependencies
├── .env.example        # Environment variables template
└── .env                # Your API keys (gitignored, not committed)
```

## Environment Variables

API keys and secrets are stored in `.env` (gitignored, never committed).

**Setup:**
```bash
cp .env.example .env
vim ~/dotfiles/.env
```

**Variables:**
- `GITHUB_TOKEN` - GitHub personal access token (gh CLI, scout)
- `ANTHROPIC_API_KEY` - Claude API key
- `BUILDKITE_TOKEN` - Buildkite API token (CI monitoring)
- `GLEAN_API_TOKEN` - Glean API token (Wayfair knowledge base)
- `GLEAN_INSTANCE` - Glean instance name (default: wayfair)
- `GIT_AUTHOR_EMAIL` - Git user email (for reference, actual value in gitconfig)
- `GIT_AUTHOR_NAME` - Git user name (for reference, actual value in gitconfig)

See `.env.example` for full list.

## Symlink Map

```
~/.bk.yaml                     -> ~/dotfiles/buildkite/.bk.yaml
~/.zshrc                       -> ~/dotfiles/zsh/.zshrc
~/.tmux.conf                   -> ~/dotfiles/tmux/tmux.conf
~/.config/tmux/scripts/        -> ~/dotfiles/tmux/scripts/
~/.gitconfig                   -> ~/dotfiles/git/gitconfig
~/.aerospace.toml              -> ~/dotfiles/aerospace/aerospace.toml
~/.config/ghostty/             -> ~/dotfiles/ghostty/
~/.config/kitty/               -> ~/dotfiles/kitty/
~/.config/nvim/                -> ~/dotfiles/nvim/
~/.config/ccstatusline/        -> ~/dotfiles/claude/ccstatusline/
~/.config/mise/config.toml     -> ~/dotfiles/.mise.toml
~/.claude/settings.json        -> ~/dotfiles/claude/settings.json (generated from template)
~/.claude/agents/              -> ~/dotfiles/claude/agents/
~/.claude/CLAUDE.md            -> ~/dotfiles/claude/CLAUDE.md
~/.pi/agent/settings.json      -> ~/dotfiles/pi/agent/settings.json
~/.pi/agent/keybindings.json   -> ~/dotfiles/pi/agent/keybindings.json
~/.pi/agent/extensions/        -> ~/dotfiles/pi/agent/extensions/*
~/.pi/agent/themes/            -> ~/dotfiles/pi/agent/themes/
~/.pi/agent/prompts/*.md       -> ~/dotfiles/pi/agent/prompts/*.md
~/.gemini/settings.json        -> ~/dotfiles/gemini/settings.json (generated from template)
~/.local/bin/gemini            -> $(npm bin -g)/gemini
~/.cursor/User/settings.json   -> ~/dotfiles/cursor/User/settings.json
~/.cursor/mcp.json             -> ~/dotfiles/cursor/mcp.json
~/.cursor/cli-config.json      -> ~/dotfiles/cursor/cli-config.json
```

## Instructions for Claude Code

When working in this dotfiles repository, follow these synchronization rules:

### Adding New Shell Tools or Aliases

1. Check if the tool is in `.mise.toml` or `Brewfile.macos`
2. Add missing tools to the appropriate file
3. Update `docs/tools/mise.md` if it's a user-facing tool
4. Update the relevant tool doc in `docs/tools/` if usage notes apply
5. Ensure zsh functions have clear comments about their dependencies

### Keeping Documentation in Sync

- Add/remove tools → update `docs/tools/mise.md`
- Add/remove shell aliases → update `docs/tools/zsh.md` if user-facing
- Add/remove symlinks → update Symlink Map above
- Add new scripts → update relevant doc in `docs/tools/`
- All docs live in `docs/` — not scattered in subdirectories

### Example Workflow

```
User: "Add a new fzf function for searching files"
Claude:
  1. Create the function in zsh/custom/05-aliases.zsh
  2. Check: Does it use fzf? → Verify in .mise.toml
  3. If missing → Add to .mise.toml
  4. Update docs/tools/mise.md and docs/tools/zsh.md
```

**Key principle:** Keep tool configs, zsh aliases, and docs/ synchronized at all times.
