# Keybindings

# Vim keybindings for command line editing
bindkey -v

# Faster mode switching (default is 0.4s which feels sluggish)
export KEYTIMEOUT=1

# Cursor shape changes between modes (works in most modern terminals)
# Block cursor for normal mode, beam cursor for insert mode
function zle-keymap-select {
  if [[ ${KEYMAP} == vicmd ]] || [[ $1 = 'block' ]]; then
    echo -ne '\e[2 q'  # Block cursor
  elif [[ ${KEYMAP} == main ]] || [[ ${KEYMAP} == viins ]] || [[ $1 = 'beam' ]]; then
    echo -ne '\e[6 q'  # Beam cursor
  fi
}
zle -N zle-keymap-select

# Initialize cursor shape for new prompts
function zle-line-init {
  echo -ne '\e[6 q'  # Start in insert mode with beam cursor
}
zle -N zle-line-init

# Better search with arrow keys (works in both modes)
bindkey '^[[A' history-search-backward
bindkey '^[[B' history-search-forward

# Edit command in external editor (Ctrl+X Ctrl+E)
autoload -U edit-command-line
zle -N edit-command-line
bindkey '^x^e' edit-command-line
bindkey -M vicmd 'v' edit-command-line  # Also 'v' in normal mode

# Keep useful emacs bindings in insert mode
bindkey '^A' beginning-of-line
bindkey '^E' end-of-line
bindkey '^K' kill-line
bindkey '^U' backward-kill-line
bindkey '^W' backward-kill-word
bindkey '^R' history-incremental-search-backward
bindkey '^P' up-history
bindkey '^N' down-history

# Vim normal mode: useful additions
bindkey -M vicmd 'H' beginning-of-line
bindkey -M vicmd 'L' end-of-line
bindkey -M vicmd '/' history-incremental-search-backward
bindkey -M vicmd '?' history-incremental-search-forward

# Fix backspace and delete in insert mode
bindkey '^?' backward-delete-char
bindkey '^H' backward-delete-char
bindkey '^[[3~' delete-char
