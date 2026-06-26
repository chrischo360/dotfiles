# Claude Code

Config location: `~/dotfiles/claude/`

## Directory Structure

```
claude/
├── AGENTS.md           # Global instructions (symlinked to ~/.claude/AGENTS.md)
├── STATE_FLOW.md       # Hook state machine documentation
├── settings.json       # Main config (permissions, model, hooks, statusline)
├── mcp-profiles.json   # Predefined MCP server combinations
├── mcp-servers.json    # MCP server definitions
├── ccstatusline/       # ccstatusline configuration
├── commands/           # Slash commands
│   ├── global/         # Available in all repos
│   └── repos/          # Per-repo commands
├── hooks/
│   ├── session/        # Session lifecycle (start, end, stop, user-input)
│   ├── tools/          # Tool tracking (pre/post tool use)
│   └── tracking/       # Metrics (tokens, costs, agents)
└── scripts/
    ├── state/          # Session state management
    ├── cost/           # Cost tracking and analysis
    ├── monitoring/     # CI/CD build monitoring
    └── utils/          # Notifications, buffers, aliases
```

## Settings

`settings.json` controls:
- Permissions (allowed/denied tools)
- Default model and mode (plan/code)
- Hooks and statusline
- Allowed directories
- MCP servers

Generated from `settings.json.template` during `install.sh` — re-run install if you move dotfiles.

## MCP Profiles

Launch Claude with predefined MCP server combinations.

**Available profiles** (defined in `mcp-profiles.json`):
- `research` - Research tools (GitHub, Sourcegraph, Docker, Glean)
- `debug` - Debugging tools (Buildkite, Playwright, Sourcegraph)
- `code-review` - Code review (GitHub + Sourcegraph)

**Interactive mode:**
```bash
claude-mcp  # Opens FZF with profiles + individual servers
```

**Non-interactive:**
```bash
claude-mcp --servers research
claude-mcp --servers github_wayfair,sourcegraph
```

**Tmux split pane:**
```bash
claude-mcp-split research
claude-mcp-split buildkite,github_wayfair
```

**Adding custom profiles:** Edit `claude/mcp-profiles.json`:
```json
{
  "profiles": {
    "my-profile": {
      "description": "Description for FZF preview",
      "servers": ["server1", "server2"]
    }
  }
}
```

## Session State Tracking

Multi-session awareness in tmux statusline. Tracks Claude Code sessions across panes.

**Display format:** `C: main📖✏️ work❓ dotfiles✅`

| Icon | Meaning | Tool |
|------|---------|------|
| 📖 | Reading | Read, Glob |
| 🔍 | Searching | Grep |
| ✏️ | Editing | Edit, Write |
| ⚙️ | Running | Bash |
| 🤖 | Delegating | Task |
| 🌐 | Fetching | WebFetch, WebSearch |
| 🔄 | Thinking | Generic active |
| ❓ | Question | AskUserQuestion |
| ✅ | Ready | Idle |

**State transitions:**
- `SessionStart` → active
- `UserPromptSubmit` → active
- `PreToolUse(AskUserQuestion)` → waiting_for_input
- `Stop` → idle

**Quick reference:**
- State file: `~/.claude/session-state.json`
- Hooks configured in: `claude/settings.json`
- tmux statusline refreshes every 2 seconds

**Debugging:**
```bash
~/dotfiles/claude/scripts/state/debug-status.sh          # View current state
tail -f ~/.claude/hook-debug.log                   # Monitor hooks in real-time
~/dotfiles/claude/scripts/state/update-session-state.sh <action>  # Manual update
# Actions: start, active, idle, waiting, stop
```

See `claude/STATE_FLOW.md` for full documentation.

## ccstatusline

Powerline-style statusline showing model, git branch, tokens, session duration.

Configure interactively:
```bash
ccstatusline
```

Or edit directly: `~/.config/ccstatusline/config.json`

## Cost Tracking

```bash
status                  # Current session
status 30000            # 30k tokens (opus)
status 30000 sonnet     # 30k tokens (sonnet)
```

**GCP Vertex AI Pricing:**

| Model | Input (per 1M) | Output (per 1M) |
|-------|----------------|-----------------|
| Claude Opus 4 | $15.00 | $75.00 |
| Claude Sonnet 4.5 | $3.00 | $15.00 |
| Claude Haiku 4 | $0.40 | $2.00 |

## Slash Commands

Commands live in `claude/commands/`:
- `global/` — available in all repos, symlinked to `~/.claude/commands/`
- `repos/<repo-name>/` — per-repo, symlinked to `<repo>/.claude/commands/`

**Adding a global command:**
```bash
echo "Your prompt" > ~/dotfiles/claude/commands/global/my-command.md
ln -s ~/dotfiles/claude/commands/global/my-command.md ~/.claude/commands/my-command.md
```

**Adding a repo-specific command:**
```bash
mkdir -p ~/dotfiles/claude/commands/repos/my-repo
echo "Repo prompt" > ~/dotfiles/claude/commands/repos/my-repo/my-command.md
ln -s ~/dotfiles/claude/commands/repos/my-repo/my-command.md ~/path/to/repo/.claude/commands/my-command.md
```
