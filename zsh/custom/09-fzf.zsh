# FZF Configuration

# Set up fzf key bindings and fuzzy completion
if [ -f ~/.fzf.zsh ]; then
  source ~/.fzf.zsh
fi

# FZF options
export FZF_DEFAULT_OPTS="--height 40% --layout=reverse --border"

# Use fd for FZF if available
if command -v fd &> /dev/null; then
  export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
  export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
fi
