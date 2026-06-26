# Dotfiles

Personal configuration files for my macOS (and Linux server) development environment — shell, editor, terminal, window manager, git, and AI coding agents (Claude Code, Pi, Devin).

## Quick Start

```bash
# Clone with submodules (zsh plugins live in submodules)
git clone --recurse-submodules git@github.com:chrischo360/dotfiles.git ~/dotfiles
cd ~/dotfiles

# If you already cloned without --recurse-submodules:
git submodule update --init --recursive

# Set up your secrets (never committed)
cp .env.example .env
$EDITOR .env

# Install: creates symlinks and sets up the dev environment
./install.sh
```

`install.sh` backs up any existing files before symlinking, processes JSON templates with path substitution, installs tools via [mise](https://mise.jdx.dev/), and wires up the configs below. See [`docs/install.md`](docs/install.md) for details.

## What's Inside

| Path | Description |
| --- | --- |
| `zsh/` | Zsh shell config, aliases, and functions |
| `nvim/` | Neovim configuration |
| `tmux/` | tmux config and scripts |
| `ghostty/` | Ghostty terminal emulator config |
| `aerospace/` | AeroSpace tiling window manager |
| `git/` | Git configuration |
| `biome/`, `lua/` | Formatter/linter configs (Biome, Stylua) |
| `buildkite/` | Buildkite CLI config |
| `claude/` | Claude Code config, hooks, and scripts |
| `pi/` | Pi coding agent config |
| `devin/` | Devin CLI global config |
| `agent/` | Shared resources (commands, hooks, skills) for Claude, Pi, and Devin |
| `scripts/` | Standalone utility scripts (theme, dev envs, notes sync) |
| `tests/` | Docker-based install test suite |
| `docs/` | Documentation (install, maintenance, per-tool reference) |
| `Brewfile.macos` | Homebrew package dependencies |
| `.mise.toml` | Tool/runtime version management |
| `.env.example` | Template for API keys and secrets |

## Dependencies

- **[Homebrew](https://brew.sh/)** — install packages with `brew bundle --file=Brewfile.macos`
- **[mise](https://mise.jdx.dev/)** — runtime/tool versions from `.mise.toml`

## Secrets

API keys and secrets live in `.env`, which is **gitignored and never committed**. Copy `.env.example` to `.env` and fill in your own values. See [`AGENTS.md`](AGENTS.md#environment-variables) for the full variable list.

## Documentation

- [`docs/install.md`](docs/install.md) — installation guide
- [`docs/maintenance.md`](docs/maintenance.md) — maintenance and package management
- [`docs/portability.md`](docs/portability.md) — path config and cross-platform notes
- [`docs/tools/`](docs/tools/) — per-tool reference docs
- [`AGENTS.md`](AGENTS.md) — repository structure and conventions for AI coding agents

## License

Personal configuration — use at your own risk.
