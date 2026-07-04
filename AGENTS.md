# Dotfiles

Personal configuration files for macOS development environment.

## Repository Structure

```
~/dotfiles/
├── aerospace/          # AeroSpace window manager config
├── biome/              # Biome JS/TS formatter config
├── buildkite/          # Buildkite CLI config
├── claude/             # Claude Code configuration and tools
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
├── devin/              # Devin CLI global config
├── git/                # Git configuration
├── ghostty/            # Ghostty terminal emulator config
├── lua/                # Lua tooling config (stylua)
├── nvim/               # Neovim configuration
├── agent/              # Shared resources for Claude, Pi, and Devin
│   ├── commands/       # Canonical command/prompt source
│   ├── hooks/          # Shared notification hook (notify.sh + click handler)
│   └── skills/         # Shared agent skills
├── pi/                 # Pi coding agent configuration
├── scripts/            # Standalone scripts (theme, codebase dev envs, notes sync)
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
- `GLEAN_MCP_AUTH_HEADER` or `GLEAN_MCP_TOKEN` - Fresh Glean MCP auth for Pi (local shell only, not dotfiles)
- `GLEAN_INSTANCE` - Glean instance name (default: wayfair)
- `GLEAN_MCP_URL` - Glean MCP endpoint
- `DD_API_KEY` - Datadog API key (Pi Datadog MCP)
- `DD_APPLICATION_KEY` - Datadog application key (Pi Datadog MCP)
- `DD_MCP_DOMAIN` - Datadog MCP domain (default: mcp.datadoghq.com)
- `DD_MCP_TOOLSETS` - Datadog MCP toolsets (default: all)
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
~/.config/nvim/                -> ~/dotfiles/nvim/
~/.config/ccstatusline/        -> ~/dotfiles/claude/ccstatusline/
~/.config/mise/config.toml     -> ~/dotfiles/.mise.toml
~/.config/devin/config.json    -> ~/dotfiles/devin/config.json
~/.config/devin/skills/        -> ~/dotfiles/devin/skills/
~/.claude/settings.json        -> ~/dotfiles/claude/settings.json (generated from template)
~/.claude/commands/            -> ~/dotfiles/claude/commands/  (global/ subdir symlinks to ~/dotfiles/agent/commands/)
~/.claude/AGENTS.md            -> ~/dotfiles/claude/AGENTS.md
~/.pi/agent/settings.json      -> ~/dotfiles/pi/agent/settings.json
~/.pi/agent/keybindings.json   -> ~/dotfiles/pi/agent/keybindings.json
~/.pi/agent/extensions/        -> ~/dotfiles/pi/agent/extensions/*
~/.pi/agent/themes/            -> ~/dotfiles/pi/agent/themes/
~/.pi/agent/prompts/           -> ~/dotfiles/agent/commands/  (shared with Claude)

# Internal dotfiles symlinks (not home directory):
~/dotfiles/claude/commands/global/ -> ~/dotfiles/agent/commands/  (makes commands available to ~/.claude/commands)

# Shared agent skills:
~/.agents/skills/<name>/       -> ~/dotfiles/agent/skills/<name>/
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
