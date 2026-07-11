# tmux

Terminal multiplexer.

Config: `~/dotfiles/tmux/tmux.conf` → `~/.tmux.conf`
Scripts: `~/dotfiles/tmux/scripts/` → `~/.config/tmux/scripts/`

Live docs: `man tmux` | `tmux list-commands`

## Prefix Key

`Ctrl+Space` (default `Ctrl+B` unbound)

## Key Bindings

### Sessions & Windows

| Key | Action |
|-----|--------|
| `Prefix+s` | FZF session switcher with preview |
| `Prefix+Enter` | Toggle last session |
| `Prefix+Space` | Toggle last window |
| `Prefix+Tab` | Toggle last pane |
| `Prefix+n` | Cycle window layout |
| `Prefix+c` | New window (same directory) |
| `Prefix+r` | Reload tmux config |
| `Prefix+R` | Reload zsh in idle panes (skips nvim/ssh) |
| `tmux-daily` | Create curated daily sessions |

### Panes

| Key | Action |
|-----|--------|
| `Prefix+|` | Split horizontal |
| `Prefix+-` | Split vertical |
| `Prefix+H/J/K/L` | Focus pane left/down/up/right |
| `Prefix+Shift+H/J/K/L` | Resize pane |

### Copy Mode (vi keys)

| Key | Action |
|-----|--------|
| `v` | Begin selection |
| `V` | Select line |
| `Ctrl+V` | Rectangle select |
| `y` / `Y` | Yank to clipboard (pbcopy) |
| `/` / `?` | Search forward/backward |
| `g` / `G` | Top/bottom of history |

### Buildkite

| Key | Action |
|-----|--------|
| `Prefix+D` | Toggle Buildkite monitor session |
| `Prefix+B` | Popup Buildkite dashboard |

### Plugins (TPM)

| Key | Action |
|-----|--------|
| `Ctrl+F` | Save session (resurrect) |
| `Ctrl+R` | Restore session (resurrect) |

## Statusline

**Left:** `[session-name]` + window list + `nvim count` on current window

**Right:** `Pi status | Claude status | Devin status | Buildkite status | date/time`

- Refreshes every 10 seconds
- Shared agent renderer: `~/.config/tmux/scripts/agent_status.sh`
- Agent state uses session-name badges colored by state: green complete, red waiting/context, yellow working/running, cyan reading/web, blue searching/delegating, magenta editing
- Pi status script: `~/.config/tmux/scripts/pi_status.sh`
- Claude status script: `~/.config/tmux/scripts/claude_status.sh`
- Devin status script: `~/.config/tmux/scripts/devin_status.sh`
- Buildkite status script: `~/.config/tmux/scripts/buildkite_status.sh`
- Nvim count script: `~/.config/tmux/scripts/nvim_status.sh`

## mpv Integration

Shows `🎵 Track Title [Time Remaining]` in statusline during playback.
Requires `socat` and mpv launched with `--input-ipc-server=/tmp/mpvsocket` (handled by `yt`/`ytv` aliases).

## Plugins

- `tmux-plugins/tpm` — plugin manager
- `tmux-plugins/tmux-resurrect` — save/restore sessions, including nvim sessions
- `tmux-plugins/tmux-continuum` — auto-save every 15 min; auto-restore disabled

## Daily Sessions

Script: `~/dotfiles/tmux/scripts/daily-sessions.sh`
LaunchAgent: `~/dotfiles/tmux/scripts/com.user.tmux-daily.plist` → `~/Library/LaunchAgents/com.user.tmux-daily.plist`

Creates missing sessions only. Current list:
- `android` → shell
- `anki-goat` → shell
- `basket-service` → shell
- `block-builder-api` → shell
- `cf-cypress` → shell
- `dotfiles` → nvim + shell
- `experience-decision-engine` → shell
- `homebase` → shell
- `ios` → shell
- `lacuna` → shell
- `leetcode` → shell
- `loyalty-membership` → shell
- `loyalty-membership-subgraph` → shell
- `loyalty-orchestrator-subgraph` → shell
- `music` → shell
- `notes` → nvim + shell
- `payments-paykit-subgraph` → shell
- `php` → shell
- `portfolio` → shell
- `server` → shell
- `sf-js-libraries` → shell
- `sf-ui-cart-and-checkout` → shell
- `sf-ui-checkout` → shell
- `sf-ui-web` → 4 shells

Full tmux-resurrect restore remains manual: `Prefix+Ctrl+r`.
