# Centralized Path Configuration

This directory contains centralized path configuration for dotfiles portability.

## paths.json

Defines all common paths used across configuration files.

**Structure:**
```json
{
  "home": "$HOME",
  "dotfiles": "$DOTFILES_DIR",
  "codebase": "$HOME/codebase",
  "local_bin": "$HOME/.local/bin",
  "pal_server": "$HOME/pal-mcp-server/pal-mcp-server"
}
```

**Usage:**

The install script (`install.sh`) reads these path definitions and uses them to generate final configuration files from templates.

**Template placeholders:**
- `{{home}}` - User home directory
- `{{dotfiles}}` - Dotfiles repository location
- `{{codebase}}` - Codebase directory
- `{{local_bin}}` - Local binary directory
- `{{pal_server}}` - PAL MCP server path

**Files using templates:**
- `claude/settings.json.template` → `~/.claude/settings.json`
- `gemini/settings.json.template` → `~/.gemini/settings.json`

**Why:**
JSON files cannot use environment variables. Templates with placeholders allow portable configuration that works across different:
- Users
- Machines
- Directory locations
- Operating systems
