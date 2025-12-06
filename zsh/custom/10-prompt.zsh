# Minimal Zsh Native Prompt
# Alternative to Starship - faster and simpler

# Load git info
autoload -Uz vcs_info
precmd() { vcs_info }

# Configure git info format
zstyle ':vcs_info:git:*' formats ' %b'  # Shows: " main"
zstyle ':vcs_info:*' enable git

# Enable prompt substitution
setopt PROMPT_SUBST

# Define prompt
# %F{color} = set foreground color
# %~ = current directory (with ~ for home)
# %(?...) = conditional: show if last command failed
PROMPT='%F{blue}%~%f%F{green}${vcs_info_msg_0_}%f
%F{%(?.green.red)}❯%f '
