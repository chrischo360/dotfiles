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
alias gs="git status -sb"
alias ga="git add"
alias gc="git commit"
alias gcam="git commit --amend"
alias gcan="git commit --amend --no-edit"
alias gp="git push"
alias gpf="git push --force-with-lease"
alias gpr="git pull --rebase"
alias gpom="git pull origin main --rebase"
alias gco="git checkout"
alias gcb="git checkout -b"
alias gl="git log --oneline --graph --decorate"
alias glog="git log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit"
alias glg="git log --graph --oneline --all --decorate"
alias gls="git log --stat"
alias gd="git diff"

# Git rebase
alias grb="git rebase"
alias grbi="git rebase -i"
alias grbc="git rebase --continue"
alias grba="git rebase --abort"

# Git branch management
alias gbd="git branch -d"
alias gbD="git branch -D"
alias gba="git branch -a"

# Git cleanup
alias gclean="git clean -fd"
alias gprune="git remote prune origin"

# Git help - show available shortcuts
alias g='echo "Git Shortcuts:
  gs       git status -sb
  ga       git add
  gc       git commit
  gcam     git commit --amend
  gcan     git commit --amend --no-edit
  gp       git push
  gpf      git push --force-with-lease
  gpr      git pull --rebase
  gpom     git pull origin main --rebase
  gco      git checkout
  gcb      git checkout -b
  gb       checkout branch (fzf)

Log:
  gl       git log --oneline --graph
  glog     git log (pretty format)
  glg      git log --graph --all
  gls      git log --stat

Diff:
  gd       git diff

Rebase:
  grb      git rebase
  grbi     git rebase -i
  grbc     git rebase --continue
  grba     git rebase --abort

Branch:
  gbd      git branch -d
  gbD      git branch -D
  gba      git branch -a

Cleanup:
  gclean   git clean -fd
  gprune   git remote prune origin"'

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
nvim-fzf() {
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

nvim-grep() {
  local result=$(rg --line-number --column --no-heading --color=always . | \
    fzf --ansi \
      --height 40% \
      --reverse \
      --border \
      --delimiter ':' \
      --preview 'bat --color=always --highlight-line {2} {1}' \
      --preview-window='up:60%:+{2}-/2')

  if [ -n "$result" ]; then
    local file=$(echo "$result" | cut -d':' -f1)
    local line=$(echo "$result" | cut -d':' -f2)
    local col=$(echo "$result" | cut -d':' -f3)
    command nvim "+call cursor($line,$col)" "$file"
  fi
}

############################# SCRIPTS ############################# 

# Nvim Memory Monitoring & Cleanup
alias memory='$DOTFILES_DIR/scripts/nvim/memory.sh'

claude-mcp() {
  command claude --strict-mcp-config --mcp-config $DOTFILES_DIR/claude/mcp-servers.json -- "$@"
}

# Claude Code - Get costs
alias claude-costs='$DOTFILES_DIR/claude/scripts/cost/analyze-costs.py'

# sf-ui-web - Build/clean utility
alias sfb='$DOTFILES_DIR/scripts/codebase/sf-ui-web/sfb.sh'

 alias cfbuild='(cd ~/codebase/cp-toolkit && cargo install --path cp --force && cargo install --path interview --force && cargo install --path interview-tui --force)'
