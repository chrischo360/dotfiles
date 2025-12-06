# FZF Configuration - Lazy Loading

# Lazy-load FZF - only initialize when first used
_fzf_loaded=0

_load_fzf() {
  if [ $_fzf_loaded -eq 1 ]; then
    return
  fi

  if [ -f ~/.fzf.zsh ]; then
    source ~/.fzf.zsh
  fi

  _fzf_loaded=1
}

# Wrapper function - loads FZF on first use
if [ -f ~/.fzf.zsh ]; then
  fzf() {
    _load_fzf
    unset -f fzf  # Remove wrapper, use real fzf
    fzf "$@"
  }
fi

# FZF options (these don't require loading)
export FZF_DEFAULT_OPTS="--height 40% --layout=reverse --border"

# Use fd for FZF if available
if command -v fd &> /dev/null; then
  export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
  export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
fi
