# Aliases

# Alacritty theme picker
alias at="$HOME/dotfiles/alacritty/scripts/alacritty-theme-picker.sh"

# Kitty - image viewer
alias icat="kitty +kitten icat"

# alias cfbuild='(cd ~/codebase/cp-toolkit && cargo install --path cp --force)'
 alias cfbuild='(cd ~/codebase/cp-toolkit && cargo install --path cp --force && cargo install --path interview --force && cargo install --path interview-tui --force)'
# Tmux - Reload zsh config in idle panes only (skips vim, ssh, etc.)
alias tmux-reload-all="~/dotfiles/tmux/scripts/reload-zsh-safe.sh"

# Modern CLI Tools (eza, bat, fd, delta)
alias ls="eza --icons"
alias ll="eza -l --icons --git"
alias la="eza -la --icons --git"
alias tree="eza --tree --icons"
alias cat="bat --style=plain --paging=never"
alias less="bat"

# Git shortcuts
alias gs="git status"
alias ga="git add"
alias gc="git commit"
alias gp="git push"
alias gl="git log --oneline --graph --decorate"
alias gd="git diff"

# Checkout local branch with fzf
gb() {
  local branch=$(git branch --format='%(refname:short)' | fzf --height 40% --reverse --border --prompt="Checkout branch: ")
  if [ -n "$branch" ]; then
    git checkout "$branch"
  fi
}

# cd to directory with fzf
cdfzf() {
  local dir=$(fd --type d --hidden --follow \
    --exclude .git \
    --exclude node_modules \
    --exclude .cache \
    --exclude Library \
    --exclude vendor \
    --exclude target \
    --exclude build \
    --exclude dist \
    --exclude .next \
    --exclude .nuxt \
    . ~ | fzf --height 40% --reverse --border --prompt="cd to directory: ")
  if [ -n "$dir" ]; then
    cd "$dir"
  fi
}

# Open file in neovim with fzf
nvimfzf() {
  local file=$(fd --type f --hidden --follow \
    --exclude .git \
    --exclude node_modules \
    --exclude .cache \
    --exclude Library \
    --exclude vendor \
    --exclude target \
    --exclude build \
    --exclude dist \
    --exclude .next \
    --exclude .nuxt \
    . ~ | fzf --height 40% --reverse --border --prompt="Open in nvim: " --preview 'bat --color=always --style=numbers --line-range=:500 {}')
  if [ -n "$file" ]; then
    nvim "$file"
  fi
}

# Search file contents with ripgrep and open in neovim (interactive)
nvimgrep() {
  local result=$(fzf --height 40% --reverse --border \
    --prompt="Search: " \
    --header="Type to search, then select file to open in nvim" \
    --disabled \
    --bind "change:reload:rg --files-with-matches --no-messages {q} ~ || true" \
    --preview "rg --color=always --context=3 {q} {}" \
    --preview-window='up:60%')

  if [ -n "$result" ]; then
    nvim "$result"
  fi
}

# Better defaults
alias grep="grep --color=auto"
alias df="df -h"
alias du="du -h"

# Nvim Memory Monitoring & Cleanup
alias nvim-report='~/dotfiles/scripts/nvim-process-report.sh'
alias nvim-summary='~/dotfiles/scripts/nvim-process-report.sh --summary'
alias nvim-notify='~/dotfiles/scripts/nvim-memory-notify.sh'
alias cleanup-nvim='~/dotfiles/scripts/cleanup-old-nvim.sh'
alias cleanup-nvim-dry='~/dotfiles/scripts/cleanup-old-nvim.sh --dry-run'
alias cleanup-nvim-idle='~/dotfiles/scripts/cleanup-old-nvim.sh --idle-only'

# Claude Code - MCP configuration aliases
# alias claude='command claude'
alias claude='command claude --strict-mcp-config ~/dotfiles/claude/no-mcp.json'
alias claude-mcp='command claude --strict-mcp-config --mcp-config ~/dotfiles/claude/mcp-servers.json'

# Claude Code - Get costs
alias claude-costs='~/dotfiles/claude/scripts/analyze-costs.py'
