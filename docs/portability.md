# Portability

## Path Configuration

**Centralized Paths:** All paths are managed through `config/paths.json`:
- `home` - User home directory
- `dotfiles` - Dotfiles repository location
- `codebase` - Development projects directory
- `local_bin` - Local binaries

**Shell Scripts:** Use `$DOTFILES_DIR` environment variable
- Set automatically in `.zshrc` — no manual configuration needed
- Works regardless of where dotfiles repository is cloned
- Dynamically detected on shell startup

**JSON Configuration Files:** Generated from templates during install
- `claude/settings.json.template` → `~/.claude/settings.json`
- `gemini/settings.json.template` → `~/.gemini/settings.json`
- Templates use placeholders like `{{dotfiles}}`, `{{home}}`
- Generated files have absolute paths substituted during `install.sh`
- Re-run `install.sh` if you move the dotfiles directory

**Neovim Lua Files:** Use `vim.fn.expand("~/")`
- Automatically expands tilde paths at runtime
- No manual configuration needed

## Template Placeholders

The install script reads `config/paths.json` and substitutes these placeholders in template files:

| Placeholder | Value |
|-------------|-------|
| `{{home}}` | User home directory |
| `{{dotfiles}}` | Dotfiles repository location |
| `{{codebase}}` | Codebase directory |
| `{{local_bin}}` | Local binary directory |

JSON files cannot use environment variables directly — templates solve this for portable configuration across different users, machines, and directory locations.

## Cross-Platform Support

**OS Detection:** `install.sh` detects macOS vs Linux
- macOS: Checks `/Applications/*.app` for GUI apps
- Linux: Uses command-line tool checks
- Font paths adapted per platform

**Supported Platforms:**
- macOS (primary)
- Linux (basic support)

## API Keys and Secrets

All sensitive credentials are stored in `.env` (gitignored):
1. Copy `.env.example` to `.env`
2. Add your actual API keys
3. Never commit `.env` to version control
