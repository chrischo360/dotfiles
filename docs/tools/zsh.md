# Zsh

Config entry: `~/dotfiles/zsh/.zshrc` → `~/.zshrc`
Custom files: `~/dotfiles/zsh/custom/` (loaded in order)

Live docs: `man zsh` | `man zshbuiltins`

## Custom File Load Order

| File | Purpose |
|------|---------|
| `01-env.zsh` | Environment variables (history, Node certs, Vertex AI, Claude models) |
| `02-paths.zsh` | PATH setup, mise activation, direnv hook |
| `03-lazy-load.zsh` | Lazy loaders for sdkman, gcloud, zoxide |
| `03-overrides.zsh` | Post-mise overrides (JAVA_HOME via sdkman, macOS only) |
| `04-platform.zsh` | Platform-specific PATH additions (macOS: PHP, Coursier, Scala CLI) |
| `05-aliases.zsh` | Aliases and functions |
| `06-work.zsh` | Wayfair-specific config |
| `07-help.zsh` | Helper functions (glob, nvim-surround, regex) |
| `08-keybindings.zsh` | Zsh line editor keybindings (vi mode) |
| `09-fzf.zsh` | fzf keybindings and config |
| `10-prompt.zsh` | Prompt setup |

## Key Environment Variables

| Variable | Value |
|----------|-------|
| `EDITOR` / `VISUAL` | `nvim` |
| `CDPATH` | `.:~:~/codebase` |
| `JAVA_HOME` | `~/.sdkman/candidates/java/current` (macOS only; Linux uses mise's java shim) |
| `CLAUDE_CODE_USE_VERTEX` | `1` |
| `ANTHROPIC_VERTEX_PROJECT_ID` | `wf-gcp-us-sf-genai-pilot-sbx` |
| `CLOUD_ML_REGION` | `us-east5` |
| `GOOGLE_CLOUD_PROJECT` | `wf-gcp-us-sf-genai-pilot-sbx` |

## Aliases

### File / Navigation
| Alias | Command |
|-------|---------|
| `ls` | `eza --icons` |
| `ll` | `eza -l --icons --git` |
| `la` | `eza -la --icons --git` |
| `tree` | `eza --tree --icons` |
| `cat` | `bat --style=plain --paging=never` |
| `less` | `bat` |

### Git
| Alias | Command |
|-------|---------|
| `gs` | `git status -sb` |
| `gc` | `git commit` |
| `gacm` | `git add . && git commit -m` |
| `gcan` | `git commit --amend --no-edit` |
| `gp` | `git push` |
| `gpr` | `git pull --rebase` |
| `gco` | `git checkout` |
| `gcb` | `git checkout -b` |
| `gl` | `git log --graph --stat ...` |
| `gd` | `git diff` |
| `grbi` | `git rebase -i` |
| `grbc` | `git rebase --continue` |
| `ghpr` | `gh pr view --web` |

### Media
| Alias | Command |
|-------|---------|
| `yt` | `mpv --no-video --input-ipc-server=/tmp/mpvsocket` |
| `ytv` | `mpv --input-ipc-server=/tmp/mpvsocket` |
| `yti` | `open -a IINA` |

### Dev Tools
| Alias | Command |
|-------|---------|
| `dev` / `d` | `$DOTFILES_DIR/scripts/dev/dev.sh` |
| `theme` | `$DOTFILES_DIR/scripts/theme` |
| `memory` | `$DOTFILES_DIR/scripts/nvim/memory.sh` |
| `bk-local` | `node $DOTFILES_DIR/scripts/codebase/buildkite-local-checks.mjs` |
| `obsidian` | Open Obsidian from terminal |
| `bk-start/stop/status/watch` | Buildkite monitor session management |
| `icat` | `kitty +kitten icat` |
| `tmux-reload` | Reload zsh in idle tmux panes |
| `tmux-daily` | Create curated daily tmux sessions |
| `cli-agent` | `cursor agent` (AI CLI switcher) |

## Plugins (git submodules)

- `zsh/plugins/zsh-autosuggestions` — command suggestions
- `zsh/plugins/fast-syntax-highlighting` — syntax highlighting

## Prompt

- Remote SSH/Mosh sessions show a red `user@host` label before the path.

## History

- Size: 50,000 entries
- Shared across sessions, timestamps included, duplicates ignored
