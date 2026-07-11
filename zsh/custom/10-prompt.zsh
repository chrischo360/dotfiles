# Minimal Zsh Native Prompt with Git Branch

# Load version control info
autoload -Uz vcs_info
precmd() { vcs_info }

# Configure vcs_info for git
zstyle ':vcs_info:git:*' formats '%F{green}%b%f'
zstyle ':vcs_info:*' enable git

# Custom function to highlight remote SSH sessions
remote_shell_badge() {
  if [[ -n "$SSH_CONNECTION$SSH_CLIENT$SSH_TTY$MOSH_CONNECTION" ]]; then
    echo "%B%F{red}!! SSH %n@%m !!%f%b "
  fi
}

# Custom function to colorize path segments
colorize_path() {
  local path_str="${PWD/#$HOME/~}"

  # If we're at root or home, just show it
  if [[ "$path_str" == "~" ]] || [[ "$path_str" == "/" ]]; then
    echo "%F{242}${path_str}%f"
    return
  fi

  # Try to find git root
  local git_root=""
  if git rev-parse --is-inside-work-tree &>/dev/null; then
    git_root=$(git rev-parse --show-toplevel 2>/dev/null)
    git_root="${git_root/#$HOME/~}"
  fi

  # If we found a git root, colorize it differently
  if [[ -n "$git_root" ]]; then
    local git_root_name="${git_root##*/}"
    local before_git="${path_str%$git_root_name*}"
    local after_git="${path_str#*$git_root_name}"

    # Build colored path: before (gray) + git-root (yellow) + after-parent (gray) + current-dir (blue)
    if [[ -n "$after_git" ]]; then
      # We're inside subdirectories of git root
      local current_dir="${path_str##*/}"
      local after_git_parent="${after_git%/*}"
      echo "%F{242}${before_git}%F{yellow}${git_root_name}%F{242}${after_git_parent}/%F{blue}${current_dir}%f"
    else
      # We're at git root
      echo "%F{242}${before_git}%F{yellow}${git_root_name}%f"
    fi
  else
    # Not in git repo, just colorize parent/current
    local parent_path="${path_str%/*}"
    local current_dir="${path_str##*/}"
    echo "%F{242}${parent_path}/%F{blue}${current_dir}%f"
  fi
}

# Define prompt
# %F{color} = set foreground color
# %~ = current directory (with ~ for home)
# %(?...) = conditional: show if last command failed
# ${vcs_info_msg_0_} = git branch from vcs_info
PROMPT='$(remote_shell_badge)$(colorize_path) ${vcs_info_msg_0_}
%F{%(?.green.red)}❯%f '
