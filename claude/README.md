# Claude Code Configuration & Tools

Configuration files and utility scripts for Claude Code with GCP Vertex AI integration.

## Statusline

Powered by [ccstatusline](https://github.com/sirmalloc/ccstatusline) - a beautiful, customizable statusline with powerline support and themes.

### Features

- Powerline-style separators with Nerd Font support
- Multiple built-in themes (dracula, nord, gruvbox, etc.)
- Real-time metrics: model name, git branch, tokens, session duration
- Interactive configuration UI
- 256-color and truecolor support

### Configuration

Configure interactively:
```bash
ccstatusline
```

Or edit the config file directly:
```bash
~/.config/ccstatusline/config.json
```

### Installation

Installed automatically by `install.sh`, or manually:
```bash
npm install -g ccstatusline
```

### Documentation

Full documentation: https://github.com/sirmalloc/ccstatusline

## 📊 Token Usage & Cost Tracking

### Quick Status Check

Use the `status` command to see current token usage and GCP Vertex AI costs:

```bash
# From anywhere (if ~/dotfiles/claude is in your PATH):
~/dotfiles/claude/status 30000 opus

# Output:
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 📊 Token Usage: 30000 / 200000 (15.0%)
# ⏳ Remaining: 170000 tokens
# 💰 Est. Cost: $0.9900 (GCP Vertex AI - opus)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Usage

```bash
status                  # Show current session (requires env vars)
status 30000            # Show status for 30k tokens (opus model)
status 30000 sonnet     # Show status for 30k tokens (sonnet model)
status 30000 haiku      # Show status for 30k tokens (haiku model)
```

### GCP Vertex AI Pricing (2025)

| Model | Input (per 1M tokens) | Output (per 1M tokens) |
|-------|----------------------|------------------------|
| Claude Opus 4 | $15.00 | $75.00 |
| Claude Sonnet 4.5 | $3.00 | $15.00 |
| Claude Haiku 4 | $0.40 | $2.00 |

**Note:** Cost estimates assume a 70/30 input/output token split, which is typical for Claude Code usage. Actual costs may vary based on your specific usage patterns.

## 🔧 Scripts

### `token-tracker.sh`
Core library for token tracking and cost calculation. Provides:
- `calculate_cost()` - Calculate GCP Vertex AI costs
- `parse_tokens()` - Parse token usage from logs or environment
- `display_status()` - Format and display status information

### `display-status.sh`
Hook-compatible status display script. Can be called:
- From Claude Code hooks
- Manually from terminal
- Via the `status` wrapper command

### `status`
User-friendly wrapper for quick status checks. Accepts:
- Token count (optional)
- Model name (optional: opus, sonnet, haiku)

### `notify.sh`
macOS notification integration for Claude Code events. Sends notifications via `terminal-notifier` for:
- SessionEnd
- AgentComplete
- Custom events

## ⚙️ Settings

## 📁 Configuration Files

Claude Code uses two different configuration files with distinct purposes:

### ~/.claude/settings.json (Your Configuration)
**Purpose**: User-managed configuration file
**Location**: `~/.claude/settings.json` (symlinked to `~/dotfiles/claude/settings.json`)
**Version Control**: ✅ Safe to commit to dotfiles (remove sensitive tokens first)

Controls:
- Permissions (allowed/denied tools)
- Default model and mode (plan/code)
- Hooks and status line
- Allowed directories
- MCP servers

**You should edit this file** to customize Claude Code's behavior.

For more configuration options, see:
- Official docs: https://code.claude.com/docs/en/settings#settings-files
- Run `claude --help` for command-line options

### ~/.claude.json (Internal State)
**Purpose**: Claude Code's internal state database (auto-managed)
**Location**: `~/.claude.json`
**Version Control**: ❌ Do NOT commit to git

Contains:
- Usage statistics (costs, tokens, session IDs)
- UI preferences (vim mode, tips seen, onboarding)
- Project-specific metadata (trusted directories, example files)
- Session history and OAuth credentials
- **Sensitive data**: API tokens, OAuth tokens

**Do NOT manually edit this file** - let Claude Code manage it.

### Viewing ~/.claude.json (Optional)

If you want easy access to view the state file from your dotfiles directory:

```bash
# Create a symlink IN dotfiles that POINTS TO the original
ln -s ~/.claude.json ~/dotfiles/claude/.claude.json

# Add to .gitignore to prevent accidental commits
echo ".claude.json" >> ~/dotfiles/claude/.gitignore
```

This keeps the real file at `~/.claude.json` (where Claude Code expects it) but lets you view it from `~/dotfiles/claude/.claude.json`.

⚠️ **Warning**: The symlink direction matters:
- ✅ **Correct**: `ln -s ~/.claude.json ~/dotfiles/claude/.claude.json` (points TO the real file)
- ❌ **Wrong**: `ln -s ~/dotfiles/claude/.claude.json ~/.claude.json` (would move the file)

### Status Line Configuration

In `~/.claude/settings.json`:

```json
{
  "statusLine": {
    "enabled": true,
    "template": "📊 {tokens_used}/{tokens_total} tokens ({tokens_percentage}%) | 💰 ${cost} | {tokens_remaining} remaining"
  }
}
```

**Note:** The `statusLine` feature may require Claude Code version with status line support. If not supported in your version, use the `status` command instead.

### Hooks Configuration

Current hooks in `settings.json`:
- **SessionEnd** - Triggered when Claude Code session ends
- **Notification** - Triggered on notifications
- **Stop** - Triggered when stopping
- **SubagentStop** - Triggered when subagent stops

All hooks currently call `notify.sh` for macOS notifications.

## 🚀 Setup

### Add to PATH (Optional)

Add to your `~/.zshrc` or `~/.bashrc`:

```bash
export PATH="$HOME/dotfiles/claude:$PATH"
```

Then you can use `status` from anywhere.

### Make Scripts Executable

```bash
chmod +x ~/dotfiles/claude/*.sh
chmod +x ~/dotfiles/claude/status
```

### Install Dependencies

For notifications:
```bash
brew install terminal-notifier
```

For cost calculations:
```bash
# bc (basic calculator) is usually pre-installed on macOS
# If not: brew install bc
```

## 💡 Tips

### Monitoring Costs During Long Sessions

```bash
# Check cost every 5 minutes during a long Claude session
watch -n 300 "~/dotfiles/claude/status 50000 opus"
```

### Integration with tmux

Add to your tmux status line (in `~/.tmux.conf`):

```tmux
set -g status-right "#(~/dotfiles/claude/status $CLAUDE_TOKENS_USED $CLAUDE_MODEL 2>/dev/null || echo '')"
```

### Alias for Quick Checks

Add to your shell config:

```bash
alias claude-cost='~/dotfiles/claude/status'
alias cc-status='~/dotfiles/claude/status'
```

## 📝 Cost Tracking Best Practices

1. **Check before starting large tasks** - Estimate token usage for complex tasks
2. **Monitor during long sessions** - Use `status` periodically
3. **Choose appropriate models** - Use Haiku for simple tasks, Opus for complex reasoning
4. **Review after sessions** - Track your spending patterns

## 🔍 Troubleshooting

### "No active Claude Code session detected"

This means the scripts can't find the `CLAUDE_TOKENS_USED` environment variable. Either:
- Manually specify token count: `status 30000`
- Run during an active Claude Code session that exports these vars

### Inaccurate cost estimates

Remember:
- Costs are estimated based on 70/30 input/output split
- Actual ratio varies by task type
- For precise costs, check your GCP billing console

### Status line not showing

The `statusLine` feature may require a newer version of Claude Code. If not available:
- Use the `status` command instead
- Add a hook to display status at session end
- Integrate with your terminal/tmux status bar

## 📚 References

- [GCP Vertex AI Pricing](https://cloud.google.com/vertex-ai/generative-ai/pricing)
- [Claude Code Documentation](https://docs.claude.com/en/docs/claude-code)
- [Claude API Models](https://docs.anthropic.com/en/docs/models-overview)
