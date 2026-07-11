# Portability

## Path Configuration

**Shell Scripts:** Use `$DOTFILES_DIR` environment variable
- Set automatically in `.zshrc` — no manual configuration needed
- Works regardless of where dotfiles repository is cloned
- Dynamically detected on shell startup

**JSON Configuration Files:** Generated from templates during install
- `claude/settings.json.template` → `~/.claude/settings.json`
- Templates use placeholders like `{{dotfiles}}`, `{{home}}`
- Generated files have absolute paths substituted during `install.sh`
- Re-run `install.sh` if you move the dotfiles directory

**Neovim Lua Files:** Use `vim.fn.expand("~/")`
- Automatically expands tilde paths at runtime
- No manual configuration needed

## Template Placeholders

`install.sh` (via `substitute_json_template`) substitutes these placeholders in
template files. The values are derived at runtime from the environment — there is
no separate paths config file to edit.

| Placeholder | Value (runtime) |
|-------------|-----------------|
| `{{home}}` | `$HOME` |
| `{{dotfiles}}` | `$DOTFILES_DIR` (location of this repo) |
| `{{codebase}}` | `$HOME/codebase` |
| `{{local_bin}}` | `$HOME/.local/bin` |

JSON files cannot use environment variables directly — templates solve this for
portable configuration across different users, machines, and directory locations.

## Cross-Platform Support

**Tooling strategy:**
- **mise** (`.mise.toml`) installs nearly all CLI tools on both macOS and Linux —
  including `neovim`, `gh`, and `delta` (via the aqua backend). This is the
  primary, cross-platform install path.
- **macOS:** `Brewfile.macos` adds GUI apps (Ghostty, AeroSpace),
  fonts, and macOS-only notifiers (`terminal-notifier`, `alerter`).
- **Linux:** `install.sh` installs base system packages via `apt-get`
  (`git`, `curl`, `build-essential`, font/runtime build deps). GUI apps and macOS
  notifiers are skipped.
- `ytfzf` is fetched via `curl` on both platforms (not in any package registry);
  the install step skips gracefully if the download fails.

**OS Detection:** `install.sh` detects macOS vs Linux
- macOS: Homebrew packages + checks `/Applications/*.app` for GUI apps
- Linux: apt base packages + command-line tool checks
- Font paths adapted per platform

**Resilience:** install steps are guarded so a single failed download or package
won't abort the whole run — failures are reported and skipped.

**Supported Platforms:**
- macOS (primary, fully supported)
- Linux (CLI environment supported via mise + apt; GUI apps are macOS-only)

**Testing Linux:** `tests/test-install.sh` runs `install.sh` in a clean Ubuntu
container (requires Docker).

## API Keys and Secrets

All sensitive credentials are stored in `.env` (gitignored):
1. Copy `.env.example` to `.env`
2. Add your actual API keys
3. Never commit `.env` to version control
