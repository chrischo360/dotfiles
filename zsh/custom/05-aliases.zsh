# Aliases

# Kitty - image viewer and PDF viewer
alias icat="kitty +kitten icat"
alias pdf="fcat"

# Tmux - Reload zsh config in idle panes only (skips vim, ssh, etc.)
alias tmux-reload="$DOTFILES_DIR/tmux/scripts/reload-zsh-safe.sh"

# Modern CLI Tools (eza, bat, fd, delta)
alias ls="eza --icons"
alias ll="eza -l --icons --git"
alias la="eza -la --icons --git"
alias tree="eza --tree --icons"
alias cat="bat --style=plain --paging=never"
alias less="bat"

# YouTube/Media playback (mpv + yt-dlp)
# IPC socket enables track info and time remaining in tmux statusline
alias yt="mpv --no-video --input-ipc-server=/tmp/mpvsocket"
alias ytv="mpv --input-ipc-server=/tmp/mpvsocket"
alias yti="open -a IINA"
alias music='yt "https://www.youtube.com/playlist?list=PLGpO1PrgW3bifY2tgAFqLN1vZWrEs2isv"'

# Dev CLI - Context-aware development commands
alias dev='$DOTFILES_DIR/scripts/dev/dev.sh'
alias d='dev'
alias theme='$DOTFILES_DIR/scripts/theme'

# Scout CLI - GitHub/Buildkite automation (optional, requires ~/codebase/scout)
if [ -d "$HOME/codebase/scout" ]; then
    alias scout="node $HOME/codebase/scout/bin/scout.js"
fi

# AI CLI Agent - easily switch between cursor/claude/etc
# Change this to switch AI providers: "claude", "cursor agent", "gemini", etc.
alias cli-agent='cursor agent'

# Pi - inject Claude's Glean MCP token for this process only
pi() {
  if [ -z "$GLEAN_MCP_TOKEN" ] && [ -z "$GLEAN_MCP_AUTH_HEADER" ] && [ -r "$HOME/.claude/.credentials.json" ]; then
    local token
    token=$(jq -r '.mcpOAuth | to_entries[] | select(.value.serverName=="glean_default" or .value.serverUrl=="https://wayfair-be.glean.com/mcp/default") | .value.accessToken' "$HOME/.claude/.credentials.json" 2>/dev/null | head -n1)

    if [ -n "$token" ] && [ "$token" != "null" ]; then
      GLEAN_MCP_TOKEN="$token" command pi "$@"
      return
    fi
  fi

  command pi "$@"
}

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
alias gl="git log --graph --stat --pretty=format:'%Cred%h%Creset%C(yellow)%d%Creset %Cgreen(%cr)%Creset %C(bold blue)<%an>%Creset%n%n    %s%n' --abbrev-commit"
alias gd="git diff"

# GitHub PR shortcuts
alias ghpr="gh pr view --web"
alias pr-merge-spam='~/dotfiles/git/scripts/pr-spam-merge.sh'

# Git rebase
alias grb="git rebase"
alias grbi="git rebase -i"
alias grbc="git rebase --continue"
alias grba="git rebase --abort"

# Git branch management
alias gba="git branch"

# Git reset
alias grsoft="git reset --soft"
alias grhard="git reset --hard"

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

# Query current buffer from all active nvim sessions
nvim-current-buffer() {
  # Find all nvim socket paths (both standalone and embedded)
  local sockets=$(
    # Standalone nvim sockets in /tmp
    find /tmp -name "nvim.*" -type d 2>/dev/null | while read -r dir; do
      ls -1 "$dir"/0 2>/dev/null
    done
    # Embedded nvim sockets (Cursor, etc.) in /var/folders/.../T/
    find /var/folders -type d -name "nvim.${USER}" 2>/dev/null | while read -r nvim_dir; do
      find "$nvim_dir" -name "nvim.*.0" 2>/dev/null
    done
  )

  if [ -z "$sockets" ]; then
    echo "No active Neovim sessions found"
    return 1
  fi

  # Detect if nvr is available
  local use_nvr=false
  if command -v nvr &> /dev/null; then
    use_nvr=true
  fi

  # Query each socket
  echo "$sockets" | while read -r socket; do
    local buffer=""
    local bufnr=""
    local pid=$(basename "$socket" | sed 's/nvim\.\([0-9]*\)\.0/\1/')

    if [[ "$use_nvr" == true ]]; then
      # Use nvr (more reliable)
      buffer=$(nvr --servername "$socket" --remote-expr "expand('%:p')" 2>/dev/null)
      bufnr=$(nvr --servername "$socket" --remote-expr "bufnr('%')" 2>/dev/null)
    else
      # Fallback to nvim --remote
      buffer=$(nvim --server "$socket" --remote-expr "expand('%:p')" 2>/dev/null)
      bufnr=$(nvim --server "$socket" --remote-expr "bufnr('%')" 2>/dev/null)
    fi

    if [ -n "$buffer" ]; then
      echo "PID $pid | Buffer #$bufnr: $buffer"
    fi
  done
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

nvim-empty() {
  NVIM_NO_SESSION=1 command nvim "$@"
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

# Buildkite monitor session management
alias bk-start='$DOTFILES_DIR/scripts/tmux/buildkite_monitor_session.sh start'
alias bk-stop='$DOTFILES_DIR/scripts/tmux/buildkite_monitor_session.sh stop'
alias bk-status='$DOTFILES_DIR/scripts/tmux/buildkite_monitor_session.sh status'
alias bk-watch='tmux attach -t buildkite-monitor'
alias tmux-daily='$DOTFILES_DIR/tmux/scripts/daily-sessions.sh'

# Buildkite local checks generator
alias bk-local='node $DOTFILES_DIR/scripts/codebase/buildkite-local-checks.mjs'

# Claude Code with interactive MCP server selection
# Usage: claude-mcp
# Opens fzf to select which MCP servers to enable (all enabled by default)
claude-mcp() {
  # Parse --servers flag for non-interactive mode
  local server_arg_mode=false
  local requested_servers=""

  if [[ "$1" == "--servers" ]]; then
    server_arg_mode=true
    requested_servers="$2"
    shift 2
  fi

  # Read available servers and profiles
  local profiles_config="$DOTFILES_DIR/claude/mcp-profiles.json"
  local servers_config="$DOTFILES_DIR/claude/mcp-servers.json"
  local available_servers=$(jq -r '.mcpServers | keys[]' "$servers_config")
  local available_profiles=$(jq -r '.profiles | keys[]' "$profiles_config" 2>/dev/null || echo "")

  # Determine selected servers
  local selected_servers=""

  if [[ "$server_arg_mode" == true ]]; then
    # Non-interactive mode: check if it's a profile name first
    if [[ -n "$available_profiles" ]] && echo "$available_profiles" | grep -q "^${requested_servers}$"; then
      # It's a profile - expand to server list
      local profile_servers=$(jq -r ".profiles.\"$requested_servers\".servers | join(\",\")" "$profiles_config")
      selected_servers=$(echo "$profile_servers" | tr ',' '\n')
      echo "Using profile '$requested_servers': $(echo "$selected_servers" | tr '\n' ', ' | sed 's/,$//')"
    else
      # Not a profile - treat as comma-separated server list
      selected_servers=$(echo "$requested_servers" | tr ',' '\n')
    fi

    # Validate each requested server exists
    while IFS= read -r server; do
      if ! echo "$available_servers" | grep -q "^${server}$"; then
        echo "Error: MCP server '$server' not found in mcp-servers.json"
        echo "Available servers: $(echo "$available_servers" | tr '\n' ', ' | sed 's/,$//')"
        return 1
      fi
    done <<< "$selected_servers"

    if [[ "$requested_servers" != *","* ]] && ! echo "$available_profiles" | grep -q "^${requested_servers}$"; then
      echo "Non-interactive mode: Using servers: $(echo "$selected_servers" | tr '\n' ', ' | sed 's/,$//')"
    fi
  else
    # Interactive mode: build selection list with profiles + individual servers
    local selection_list=""

    # Add profiles section
    if [[ -n "$available_profiles" ]]; then
      selection_list+="=== PROFILES ==="$'\n'
      while IFS= read -r profile; do
        local servers=$(jq -r ".profiles.\"$profile\".servers | join(\",\")" "$profiles_config")
        selection_list+="📦 $profile → $servers"$'\n'
      done <<< "$available_profiles"
      selection_list+=$'\n'
    fi

    # Add individual servers section
    selection_list+="=== INDIVIDUAL SERVERS ==="$'\n'
    selection_list+="$available_servers"

    # Launch FZF with enhanced preview
    local fzf_selection=$(echo "$selection_list" | \
      fzf --multi \
        --height 50% \
        --reverse \
        --border \
        --bind 'ctrl-a:select-all' \
        --bind 'ctrl-d:deselect-all' \
        --bind 'tab:toggle' \
        --prompt="Select profile or servers (Tab toggle, Enter confirm): " \
        --header="Choose a profile or select individual servers" \
        --preview "if [[ {} == \"📦\"* ]]; then
          profile=\$(echo {} | awk '{print \$2}');
          jq \".profiles.\\\"\$profile\\\"\" $profiles_config;
        elif [[ {} != \"===\"* ]] && [[ -n {} ]]; then
          jq --arg s {} '.mcpServers[\$s]' $servers_config;
        fi" \
        --preview-window='right:60%')

    if [[ -z "$fzf_selection" ]]; then
      echo "No servers selected. Running Claude without MCP servers."
      # Forward any remaining arguments to Claude
      command claude "$@"
      return
    fi

    # Parse FZF selection - expand profiles
    while IFS= read -r line; do
      if [[ "$line" == "📦"* ]]; then
        # Profile selected - extract profile name and expand
        local profile_name=$(echo "$line" | awk '{print $2}')
        local profile_servers=$(jq -r ".profiles.\"$profile_name\".servers[]" "$profiles_config")
        selected_servers+="$profile_servers"$'\n'
      elif [[ "$line" != "==="* ]] && [[ -n "$line" ]]; then
        # Individual server selected
        selected_servers+="$line"$'\n'
      fi
    done <<< "$fzf_selection"

    # Remove duplicates and trailing newline
    selected_servers=$(echo "$selected_servers" | sort -u | grep -v '^$')
  fi

  if [[ -z "$selected_servers" ]]; then
    echo "No servers selected. Running Claude without MCP servers."
    # Forward any remaining arguments to Claude
    command claude "$@"
    return
  fi

  # Create temporary mcp-servers.json with only selected servers
  local temp_mcp_config="/tmp/claude-mcp-$$.json"

  # Build JSON with selected servers
  local servers_json="{"
  local first=true
  while IFS= read -r server; do
    if [[ "$first" == true ]]; then
      first=false
    else
      servers_json+=","
    fi
    local server_config=$(jq ".mcpServers.\"$server\"" "$servers_config")
    servers_json+="\"$server\":$server_config"
  done <<< "$selected_servers"
  servers_json+="}"

  echo "{\"mcpServers\":$servers_json}" > "$temp_mcp_config"

  echo "Enabled MCP servers: $(echo "$selected_servers" | tr '\n' ', ' | sed 's/,$//')"

  # Run Claude with the temporary config (remaining args in $@ are forwarded)
  command claude --strict-mcp-config --mcp-config "$temp_mcp_config" "$@"

  # Clean up temp file
  rm -f "$temp_mcp_config"
}

# Spawn Claude with MCP in tmux split
# Usage: claude-mcp-split "code-review"              # Profile
#        claude-mcp-split "buildkite,github_wayfair" # Individual servers
claude-mcp-split() {
  local profile_or_servers="${1:-code-review}"

  if [[ -z "$TMUX" ]]; then
    echo "Error: Not in a tmux session. Use 'claude-mcp --servers \"$profile_or_servers\"' instead."
    return 1
  fi

  tmux split-window -h "claude-mcp --servers '$profile_or_servers'"
  echo "New Claude session with MCP started in right pane."
  echo "Profile/Servers: $profile_or_servers"
  echo "Switch to it with: Ctrl-b o"
}

# Claude Code - default launcher with MCP servers
alias claude='claude-mcp --servers sourcegraph,glean_default,outline'

# Claude Code - Get costs
alias claude-costs='$DOTFILES_DIR/claude/scripts/cost/analyze-costs.py'

# Garden - Deploy to ephemeral namespace from local CLI
# Usage: garden-deploy <namespace> [garden-flags...]
alias garden-deploy='$DOTFILES_DIR/scripts/codebase/garden-deploy.sh'

# sf-ui-web - Development environment setup
alias sf-ui-web-dev='$DOTFILES_DIR/scripts/codebase/sf-ui-web/setup-dev-env.sh'

# sf-ui-checkout - Development environment setup
alias sf-ui-checkout-dev='$DOTFILES_DIR/scripts/codebase/sf-ui-checkout/setup-dev-env.sh'

# alias cfbuild='(cd ~/codebase/cp-toolkit && cargo install --path cp --force && cargo install --path interview --force && cargo install --path interview-tui --force)'
alias cf-dev="cargo run -p coachforces-cli --release --"

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

# Sync server from remote Windows machine
alias sync-server='rsync -avz --progress --rsync-path="wsl rsync" --exclude-from="$HOME/.rsyncignore" homeserver-remote:/mnt/c/Users/chris/codebase/server/ ~/server/'

# Storefront PR review complexity score
alias sage-pr-score="node $DOTFILES_DIR/scripts/sage-pr-score.mjs"
