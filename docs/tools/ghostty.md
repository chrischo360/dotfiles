# Ghostty

Primary terminal emulator. Modern GPU-accelerated, written in Zig.

Config: `~/dotfiles/ghostty/config` → `~/.config/ghostty/`

## Specs

- TERM: `xterm-ghostty`
- Theme: GitHub Dark Dimmed (inline colors)
- Features: Shell integration, OSC 52 clipboard, Kitty graphics protocol

## Fonts

**Installed:**
- **JetBrains Mono** - Optimized for coding, 139 ligatures
- **Cascadia Code** - Microsoft's modern terminal font
- **Source Code Pro** - Adobe's refined design

**Switch fonts:**
```bash
ghostty-font                 # Show current font
ghostty-font jetbrains       # JetBrains Mono (ExtraBold)
ghostty-font cascadia        # Cascadia Code (SemiBold)
ghostty-font source          # Source Code Pro (SemiBold)
```

After switching, reload config: `Cmd+Shift+,` (or restart Ghostty)

Verify: `ghostty +show-config | grep font-family`

**Manual:** Edit `~/dotfiles/ghostty/config`:
```
font-family = JetBrainsMono Nerd Font Mono
font-family = CaskaydiaCove Nerd Font Mono
font-family = SauceCodePro Nerd Font Mono
```

## Kitty (Alternative)

GPU-accelerated with image protocol support. Required for fancy-cat PDF viewer.

Config: `~/dotfiles/kitty/kitty.conf` → `~/.config/kitty/`
- TERM: `xterm-kitty`
- Theme: GitHub Dark Dimmed (via current-theme.conf)

## Switching Terminals

- Change default: System Settings → Desktop & Dock → Default Terminal
- Launch explicitly: `open -a Ghostty` / `open -a kitty`
