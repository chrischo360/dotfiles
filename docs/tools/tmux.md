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

**Left:** `[session-name]`

**Right:** `Claude status | Buildkite status | CPU% | RAM% | date/time`

- Refreshes every 2 seconds
- Claude status script: `~/.config/tmux/scripts/claude_status.sh`
- Buildkite status script: `~/.config/tmux/scripts/buildkite_status.sh`

## mpv Integration

Shows `🎵 Track Title [Time Remaining]` in statusline during playback.
Requires `socat` and mpv launched with `--input-ipc-server=/tmp/mpvsocket` (handled by `yt`/`ytv` aliases).

## Plugins

- `tmux-plugins/tpm` — plugin manager
- `tmux-plugins/tmux-resurrect` — save/restore sessions
- `tmux-plugins/tmux-continuum` — auto-save every 15 min, auto-restore
- `tmux-plugins/tmux-cpu` — CPU/RAM metrics for statusline
