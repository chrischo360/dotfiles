# mise

Dev tool manager. Replaces fnm, pyenv, rbenv. Cross-platform (macOS, Linux, Docker).

Config: `~/dotfiles/.mise.toml` → `~/.config/mise/config.toml`
macOS apps: `~/dotfiles/Brewfile.macos`

## Tools (from .mise.toml)

**Language Runtimes:** node (lts), python, ruby, bun, deno, scala

Java is managed by sdkman, not mise.

**Build Tools:** yarn, maven, sbt, kubectl, gradle (vfox), pipx (asdf)

**Shell Enhancements:** zoxide, eza, bat, fd, ripgrep, fzf, yt-dlp

**Terminal & Editors:** tmux, neovim

**Version Control:** git, gh, delta

**Dev Tools:** jq, mkcert, direnv, just

**npm Globals:** ccstatusline, @google/gemini-cli, prettier, prettier-plugin-svelte

**Zsh Plugins (git submodules):** zsh-autosuggestions, fast-syntax-highlighting

## macOS-Only (Brewfile.macos)

**CLI:** terminal-notifier, rsync, curl, swiftlint, mpv

**Apps:** aerospace, docker-desktop, claude-code, chromium, homerow

**Fonts:** font-jetbrains-mono-nerd-font

## Usage

```bash
mise install              # Install all tools from .mise.toml
mise upgrade              # Update all tools
mise upgrade node         # Update specific tool
mise list                 # List installed tools
mise ls --current         # Show which config provides each tool
mise registry <tool>      # Search available tools
```

**Add a new tool:** Edit `.mise.toml`, then run `mise install`

**macOS app:** Edit `Brewfile.macos`, then run `brew bundle --file=~/dotfiles/Brewfile.macos`

## Backends

- Most tools: `aqua` backend (pre-built binaries from GitHub releases)
- gradle: `vfox` backend (downloads from gradle.org)
- pipx: `asdf` backend (avoids GitHub API issues)

Set `AQUA_GITHUB_TOKEN` in `~/dotfiles/.env` to avoid GitHub API rate limits.
