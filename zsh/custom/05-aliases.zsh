# Aliases

# Alacritty theme picker
alias at="$HOME/dotfiles/alacritty/scripts/alacritty-theme-picker.sh"

# CodeForces - Find Next Problem
alias cfnext="(cd $HOME/codebase/codeforces && cargo run -p tools --bin next-unsolved)"
alias cfnext800="cargo run --bin next-unsolved -- --level 800"
alias cfnext1200="cargo run --bin next-unsolved -- --level 1200"

# CodeForces - Progress Tracking
alias cfadd="(cd $HOME/codebase/codeforces/training && cargo run -- add)"
alias cfshow="(cd $HOME/codebase/codeforces/training && cargo run -- show)"

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
