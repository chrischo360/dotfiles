# AeroSpace

Tiling window manager for macOS.

Config: `~/dotfiles/aerospace/aerospace.toml` → `~/.aerospace.toml`

Live docs: `aerospace --help` | Web: https://nikitabobko.github.io/AeroSpace/commands

## Settings

- Layout: tiles (default), accordion
- Gaps: all zero (no gaps between windows or screen edges)
- Mouse follows focus on monitor change: enabled
- Auto-unhide macOS hidden apps: enabled

## Keybindings

### Focus & Layout

| Key | Action |
|-----|--------|
| `Cmd+Alt+H/J/K/L` | Focus left/down/up/right |
| `Alt+/` | Toggle tiles horizontal/vertical |
| `Alt+,` | Toggle accordion horizontal/vertical |
| `Alt+-` | Resize smart -50 |
| `Alt+=` | Resize smart +50 |

### Workspaces

| Key | Action |
|-----|--------|
| `Cmd+1–5` | Switch to workspace 1–5 |
| `Ctrl+Alt+1–5` | Move window to workspace 1–5 |
| `Cmd+Tab` | Toggle last workspace |

### Service Mode (`Ctrl+Alt+;`)

| Key | Action |
|-----|--------|
| `Esc` | Reload config + exit service mode |
| `r` | Flatten workspace tree (reset layout) |
| `f` | Toggle floating/tiling |
| `Backspace` | Close all windows but current |
| `Alt+Shift+H/J/K/L` | Join with left/down/up/right pane |
| `↑/↓` | Volume up/down |
| `Shift+↓` | Mute |

## Workspace Layout

| Workspace | Monitor | Apps |
|-----------|---------|------|
| 1 | 1 | Chrome |
| 2 | 2 | Editor + Terminal (Kitty) |
| 3 | 2 | Spotify, Slack |
| 4 | 3 | Bitwarden |
| 5 | 3 | — |

## App Rules

Apps auto-assigned to workspaces on window detection:
- `com.google.Chrome` → workspace 1
- `net.kovidgoyal.kitty` → workspace 2
- `com.spotify.client` → workspace 3
- `com.tinyspeck.slackmacgap` → workspace 3
- `com.bitwarden.desktop` → workspace 4

Find app ID: `osascript -e 'id of app "AppName"'`
