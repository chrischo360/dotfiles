# Minimal Zsh Native Prompt with Git Branch

# Load version control info
autoload -Uz vcs_info
precmd() { vcs_info }

# Configure vcs_info for git
zstyle ':vcs_info:git:*' formats '%F{yellow}%b%f'
zstyle ':vcs_info:*' enable git

# Define prompt
# %F{color} = set foreground color
# %~ = current directory (with ~ for home)
# %(?...) = conditional: show if last command failed
# ${vcs_info_msg_0_} = git branch from vcs_info
PROMPT='%F{blue}%~%f ${vcs_info_msg_0_}
%F{%(?.green.red)}❯%f '
