# Dotfiles

Personal configuration files for my macOS (and Linux server) development environment — shell, editor, terminal, window manager, git, and AI coding agents (Claude Code, Pi, Devin).

## Fresh Machine Setup

Bootstrapping a brand-new Mac from zero (no git, no SSH key, no Homebrew yet).
If you already have git + SSH access to GitHub configured, skip to
[Quick Start](#quick-start).

### 0. Prerequisites: Command Line Tools, SSH, Homebrew

```bash
# 1. Install Xcode Command Line Tools (provides git, ssh, curl, make, etc.)
xcode-select --install
# Click "Install" in the dialog that pops up, then wait for it to finish.
# Re-run this command to check progress: `xcode-select -p` should print a path once done.

# 2. Generate an SSH key for GitHub (skip if ~/.ssh/id_ed25519 already exists)
ssh-keygen -t ed25519 -C "your_email@example.com"
# Accept the default path (~/.ssh/id_ed25519) and optionally set a passphrase.

# 3. Start the ssh-agent and add the key (also stores the passphrase in Keychain)
eval "$(ssh-agent -s)"
mkdir -p ~/.ssh
cat <<'EOF' >> ~/.ssh/config
Host github.com
  AddKeysToAgent yes
  UseKeychain yes
  IdentityFile ~/.ssh/id_ed25519
EOF
ssh-add --apple-use-keychain ~/.ssh/id_ed25519

# 4. Copy the public key and add it to GitHub -> Settings -> SSH and GPG keys -> New SSH key
#    https://github.com/settings/ssh/new
pbcopy < ~/.ssh/id_ed25519.pub

# 5. Verify GitHub SSH access
ssh -T git@github.com
# Expect: "Hi <username>! You've successfully authenticated..."

# 6. Install Homebrew (needed by install.sh for macOS packages/apps)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
# Follow the printed instructions to add brew to your PATH for this shell, e.g.:
eval "$(/opt/homebrew/bin/brew shellenv)"
```

### Quick Start

```bash
# Clone with submodules (zsh plugins live in submodules)
git clone --recurse-submodules git@github.com:chrischo360/dotfiles.git ~/dotfiles
cd ~/dotfiles

# If you already cloned without --recurse-submodules:
git submodule update --init --recursive

# Set up your secrets (never committed)
cp .env.example .env
$EDITOR .env
# At minimum, set GITHUB_TOKEN (a GitHub personal access token, separate from
# the SSH key above) to avoid API rate limits when mise installs tools via its
# aqua backend. https://github.com/settings/tokens

# Install: creates symlinks and sets up the dev environment
./install.sh

# Reload your shell to pick up the new config
exec zsh
```

`install.sh` backs up any existing files before symlinking, processes JSON templates with path substitution, installs tools via [mise](https://mise.jdx.dev/), and wires up the configs below. See [`docs/install.md`](docs/install.md) for details.

### After Installing

- **Restart your terminal** (or `exec zsh`) so the new `.zshrc` and PATH take effect.
- **macOS permissions:** grant Accessibility access to AeroSpace
  (System Settings → Privacy & Security → Accessibility) so window management works.
- **Git identity:** confirm `git config user.email` matches you — personal repos
  under `~/dotfiles` and `~/codebase/lacuna` auto-switch identity via
  `git/gitconfig-personal` (see [`git/gitconfig`](git/gitconfig)); edit that file
  if the personal email is wrong.
- **Fonts:** if `install.sh` reports JetBrainsMono Nerd Font missing, re-run
  `brew bundle --file=Brewfile.macos` or install it manually from
  [nerdfonts.com](https://www.nerdfonts.com/).
- **Re-run safely:** `./install.sh` is idempotent — re-run it any time (e.g. after
  `git pull`) to pick up new symlinks or tools.

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
