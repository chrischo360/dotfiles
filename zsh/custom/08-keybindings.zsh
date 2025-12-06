# Keybindings

# Vim keybindings
bindkey -v

# Better search with arrow keys
bindkey '^[[A' history-search-backward
bindkey '^[[B' history-search-forward

# Edit command in editor
autoload -U edit-command-line
zle -N edit-command-line
bindkey '^x^e' edit-command-line

# Restore some emacs bindings in vim mode
bindkey '^A' beginning-of-line
bindkey '^E' end-of-line
bindkey '^K' kill-line
bindkey '^R' history-incremental-search-backward
