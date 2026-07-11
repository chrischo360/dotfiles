# Pi

AI coding agent (alternative to Claude Code).

Config: `~/dotfiles/pi/agent/` → `~/.pi/agent/`

Live docs: `pi --help`

## Settings

`~/dotfiles/pi/agent/settings.json`:
- Provider: `anthropic-vertex` (GCP Vertex AI)
- Default model: `claude-sonnet-4-6`
- Theme: `papercolor-light`
- Prompts: loads from `~/dotfiles/claude/commands/global` (shared with Claude Code)
- Thinking: off by default

## Extensions

Auto-loaded from `~/.pi/agent/extensions/` (symlinked from `~/dotfiles/pi/agent/extensions/`):

| Extension | Purpose |
|-----------|---------|
| `anthropic-vertex/` | GCP Vertex AI provider |
| `mcp-glean/` | Glean MCP tools |
| `mcp-sourcegraph/` | Sourcegraph tools |
| `mcp-datadog/` | Datadog MCP tools |
| `plan-mode/` | Read-only exploration mode with todo tracking |
| `protected-paths.ts` | Prevents edits to sensitive paths |
| `session-status.ts` | Session status display |
| `theme-sync.ts` | Syncs theme with system |
| `web-tools.ts` | Web search/fetch tools |

## Glean MCP

The `pi` zsh wrapper injects Claude's Glean MCP OAuth token from `~/.claude/.credentials.json` for the Pi process. The Glean extension also reuses and refreshes that token when available.

Refresh/check manually:

```bash
node ~/dotfiles/scripts/dev/refresh-glean-mcp-token.mjs
```

If credentials are missing, run Claude with `glean_default` once:

```bash
claude-mcp --servers glean_default
```

Manual override, if needed:

```bash
export GLEAN_MCP_AUTH_HEADER="Bearer <token>"
# or
export GLEAN_MCP_TOKEN="<token>"
```

Do not store Glean tokens in dotfiles. `zsh/custom/01-env.zsh` only sets:

```bash
export GLEAN_INSTANCE="wayfair"
export GLEAN_MCP_URL="https://wayfair-be.glean.com/mcp/default"
```

Usage:
- `glean_search`: document discovery with short targeted keywords.
- `glean_chat`: synthesis across sources.
- `glean_read_document`: fetch full content after search.
- `glean_employee_search`, `glean_gmail_search`, `glean_meeting_lookup`, `glean_read_memory`: use for people, email, calendar, and personalization queries.

## Plan Mode

Toggle: `/plan` command or `Ctrl+Alt+P`

- Restricts tools to: `read`, `bash` (read-only cmds), `grep`, `find`, `ls`, `questionnaire`
- Status indicator: `⏸ plan` in footer
- After planning, prompts: Execute / Stay in plan mode / Refine

See `~/dotfiles/pi/agent/extensions/plan-mode/index.ts` for implementation.

## Keybindings

`~/dotfiles/pi/agent/keybindings.json` — vim-friendly editor navigation:

| Key | Action |
|-----|--------|
| `Ctrl+P/N` | Cursor up/down |
| `Ctrl+B/F` | Cursor left/right |
| `Alt+B/F` | Word left/right |
| `Ctrl+A/E` | Line start/end |
| `Ctrl+W` | Delete word back |
| `Ctrl+K` | Delete to line end |
| `Ctrl+U` | Delete to line start |
| `Shift+Enter` | New line |
| `Enter` | Submit |

## Prompts

Slash command prompts at `~/dotfiles/pi/agent/prompts/`:
`commit`, `debug`, `explain`, `migrate`, `perf`, `refactor`, `review`
