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

**Available models:**
- `anthropic-vertex/claude-haiku-4-5-20251001`
- `anthropic-vertex/claude-sonnet-4-6`
- `anthropic-vertex/claude-opus-4-6`
- `anthropic-vertex/claude-opus-4-7`

## Extensions

Auto-loaded from `~/.pi/agent/extensions/` (symlinked from `~/dotfiles/pi/agent/extensions/`):

| Extension | Purpose |
|-----------|---------|
| `anthropic-vertex/` | GCP Vertex AI provider |
| `plan-mode/` | Read-only exploration mode with todo tracking |
| `protected-paths.ts` | Prevents edits to sensitive paths |
| `session-status.ts` | Session status display |
| `theme-sync.ts` | Syncs theme with system |
| `web-tools.ts` | Web search/fetch tools |

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
