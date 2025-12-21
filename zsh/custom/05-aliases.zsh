# Aliases

# Kitty - image viewer
alias icat="kitty +kitten icat"

# Tmux - Reload zsh config in idle panes only (skips vim, ssh, etc.)
alias tmux-reload="$DOTFILES_DIR/tmux/scripts/reload-zsh-safe.sh"

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

# Grep Shortcuts
alias grep="grep --color=auto"
alias df="df -h"
alias du="du -h"

##########################################Functions##########################################
# Checkout local branch with fzf
gb() {
  local branch=$(git branch --format='%(refname:short)' | fzf --height 40% --reverse --border --prompt="Checkout branch: ")
  if [ -n "$branch" ]; then
    git checkout "$branch"
  fi
}

# Search file contents with ripgrep and open in neovim (interactive)
nvim() {
  # If arguments provided, use actual nvim
  if [ $# -gt 0 ]; then
    command nvim "$@"
    return
  fi

  # No arguments: use fzf search
  local result=$(fzf --height 40% --reverse --border \
    --prompt="Search: " \
    --header="Type to search, then select file to open in nvim" \
    --disabled \
    --bind "change:reload:rg --files-with-matches --no-messages {q} . || true" \
    --preview "rg --color=always --context=3 {q} {}" \
    --preview-window='up:60%')

  if [ -n "$result" ]; then
    command nvim "$result"
  fi
}


############################# SCRIPTS ############################# 

# Nvim Memory Monitoring & Cleanup
alias memory='$DOTFILES_DIR/scripts/nvim/memory.sh'

claude-mcp() {
  command claude --strict-mcp-config --mcp-config $DOTFILES_DIR/claude/mcp-servers.json -- "$@"
}

# Claude Code - Get costs
alias claude-costs='$DOTFILES_DIR/claude/scripts/analyze-costs.py'

# sf-ui-web - Build/clean utility
alias sfb='$DOTFILES_DIR/scripts/codebase/sf-ui-web/sfb.sh'

 alias cfbuild='(cd ~/codebase/cp-toolkit && cargo install --path cp --force && cargo install --path interview --force && cargo install --path interview-tui --force)'
