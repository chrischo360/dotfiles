# Aliases

# Alacritty theme picker
alias at="$HOME/dotfiles/alacritty/scripts/alacritty-theme-picker.sh"

# CodeForces - Unified CLI (installed to ~/.cargo/bin)
alias cfbuild='(cd ~/codebase/codeforces && cargo install --path cf-cli --force)'

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
