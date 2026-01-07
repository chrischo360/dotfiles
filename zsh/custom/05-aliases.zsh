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
alias gc="git commit"
alias gacm="ga . && gc -m"
alias gcam="git commit --amend"
alias gcan="git commit --amend --no-edit"
alias gp="git push"
alias gpr="git pull --rebase"
alias gpomr="git pull origin main --rebase"
alias gpomm="git pull origin main --merge"
alias gco="git checkout"
alias gcb="git checkout -b"
alias gl="git log --graph --stat --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit"
alias gd="git diff"

# Git rebase
alias grb="git rebase"
alias grbi="git rebase -i"
alias grbc="git rebase --continue"
alias grba="git rebase --abort"

# Git branch management
alias gba="git branch -a"

# Git cleanup
alias gclean="git clean -fd"
alias gprune="git remote prune origin"

# Grep Shortcuts
alias grep="grep --color=auto"
alias df="df -h"
alias du="du -h"

##########################################Functions##########################################
# Git add files interactively with fzf (supports multi-select with Tab)
ga() {
  # If arguments provided, use regular git add
  if [ $# -gt 0 ]; then
    git add "$@"
    return
  fi

  # No arguments: use fzf to select files
  local files=$(git status --short | \
    fzf --multi \
      --height 40% \
      --reverse \
      --border \
      --prompt="Select files to stage (Tab for multi-select): " \
      --preview 'git diff --color=always {2}' \
      --preview-window='right:60%' | \
    awk '{print $2}')

  if [ -n "$files" ]; then
    echo "$files" | while read -r file; do
      git add "$file"
      echo "Staged: $file"
    done
  fi
}

# Git toggle staging with fzf - stage unstaged files, unstage staged files
grs() {
  # If arguments provided, use regular git restore --staged
  if [ $# -gt 0 ]; then
    git restore --staged "$@"
    return
  fi

  # No arguments: use fzf to select files and toggle their staging status
  local selections=$(git status --short | \
    fzf --multi \
      --height 40% \
      --reverse \
      --border \
      --prompt="Select files to toggle staging (Tab for multi-select): " \
      --preview 'git diff --color=always {2} 2>/dev/null || git diff --cached --color=always {2}' \
      --preview-window='right:60%')

  if [ -n "$selections" ]; then
    echo "$selections" | while read -r line; do
      local file_status=$(echo "$line" | awk '{print $1}')
      local file=$(echo "$line" | awk '{print $2}')

      # First character indicates staging area status
      local staged_char="${file_status:0:1}"

      # Check if file is staged (first char is M, A, D, R, C, not space or ?)
      if [[ "$staged_char" != " " && "$staged_char" != "?" ]]; then
        git restore --staged "$file"
        echo "Unstaged: $file"
      else
        git add "$file"
        echo "Staged: $file"
      fi
    done
  fi
}

# Checkout local branch with fzf
gb() {
  local branch=$(git branch --format='%(refname:short)' | fzf --height 40% --reverse --border --prompt="Checkout branch: ")
  if [ -n "$branch" ]; then
    git checkout "$branch"
  fi
}

# Git diff with recent commits using fzf
gdc() {
  local commit=$(git log --oneline --color=always -50 | \
    fzf --ansi \
      --height 40% \
      --reverse \
      --border \
      --prompt="Select commit to diff against: " \
      --preview 'git show --color=always {1}' \
      --preview-window='right:60%')

  if [ -n "$commit" ]; then
    local commit_hash=$(echo "$commit" | awk '{print $1}')
    git --no-pager diff "$commit_hash"
  fi
}

# Git delete branches using fzf (supports multi-select with Tab)
gbd() {
  local branches=$(git branch --format='%(refname:short)' | \
    grep -v "^$(git branch --show-current)$" | \
    fzf --multi \
      --height 40% \
      --reverse \
      --border \
      --prompt="Select branches to delete (Tab for multi-select): " \
      --preview 'git log --oneline --graph --color=always {}' \
      --preview-window='right:60%')

  if [ -n "$branches" ]; then
    echo "$branches" | while read -r branch; do
      git branch -D "$branch"
    done
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

# sf-ui-checkout - Development environment setup
alias setup-sf-checkout='$DOTFILES_DIR/scripts/codebase/sf-ui-checkout/setup-dev-env.sh'

alias cfbuild='(cd ~/codebase/cp-toolkit && cargo install --path cp --force && cargo install --path interview --force && cargo install --path interview-tui --force)'

# Cursor Agent
alias cursor-gemini='cursor agent --model gemini-3-pro'
alias cursor-flash='cursor agent --model gemini-3-flash'

alias cursor-opus='cursor agent --model opus-4.5'
alias cursor-sonnet='cursor agent --model sonnet-4.5'

alias cursor-opus-thinking='cursor agent --model opus-4.5-thinking'
alias cursor-sonnet-thinking='cursor agent --model sonnet-4.5-thinking'

# PHP Code Quality Tools
# Requires being in a PHP project root with includes/sdk/composer-packages/bin/

# PHP sniff - checks changed files if no args given, otherwise checks specified files
php-sniff() {
  if [ $# -eq 0 ]; then
    # No arguments: check all changed PHP files
    local php_files=$(git diff --name-only --diff-filter=ACMR | grep '\.php$')

    if [ -z "$php_files" ]; then
      echo "No changed PHP files found in working directory"
      return 0
    fi

    echo "Checking changed PHP files:"
    echo "$php_files" | sed 's/^/  - /'
    echo ""

    echo "$php_files" | xargs /opt/homebrew/opt/php@8.1/bin/php includes/sdk/composer-packages/bin/phpcs --standard=CSNStores --warning-severity=0
  else
    # Arguments provided: check specified files
    /opt/homebrew/opt/php@8.1/bin/php includes/sdk/composer-packages/bin/phpcs --standard=CSNStores --warning-severity=0 "$@"
  fi
}

# PHP fix - fixes changed files if no args given, otherwise fixes specified files
php-fix() {
  if [ $# -eq 0 ]; then
    # No arguments: fix all changed PHP files
    local php_files=$(git diff --name-only --diff-filter=ACMR | grep '\.php$')

    if [ -z "$php_files" ]; then
      echo "No changed PHP files found in working directory"
      return 0
    fi

    echo "Fixing changed PHP files:"
    echo "$php_files" | sed 's/^/  - /'
    echo ""

    echo "$php_files" | xargs /opt/homebrew/opt/php@8.1/bin/php includes/sdk/composer-packages/bin/phpcbf --standard=CSNStores
  else
    # Arguments provided: fix specified files
    /opt/homebrew/opt/php@8.1/bin/php includes/sdk/composer-packages/bin/phpcbf --standard=CSNStores "$@"
  fi
}
