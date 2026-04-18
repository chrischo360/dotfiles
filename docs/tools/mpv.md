# mpv + yt-dlp

Play YouTube videos/audio from terminal.

## Usage

```bash
mpv "URL"                          # Video playback
mpv --no-video "URL"               # Audio only
mpv "https://youtube.com/playlist?list=PLAYLIST_ID"   # Playlist
mpv --shuffle "URL"                # Shuffle playlist
mpv --start=1:30 "URL"            # Start at timestamp
```

**Aliases:**
```bash
yt "URL"    # Audio-only
ytv "URL"   # Video playback
```

## Keyboard Controls

| Key | Action |
|-----|--------|
| `Space` | Pause/play |
| `←/→` | Seek backward/forward |
| `↑/↓` | Volume |
| `f` | Fullscreen |
| `q` | Quit |

## Tmux Integration

Shows `🎵 Track Title [Time Remaining]` in left statusline during playback.
Format: `[session] 🎵 Rick Astley - Never... [2:34]`

Requires `socat` for IPC: `brew install socat`
