# Profiling - uncomment to debug slow startup
# zmodload zsh/zprof

# PHP 8.1 - Set as default
export PATH="/opt/homebrew/opt/php@8.1/bin:$PATH"
export PATH="/opt/homebrew/opt/php@8.1/sbin:$PATH"

# Oh My Zsh Configuration - Optimized for Speed
export ZSH="$HOME/.oh-my-zsh"

# Disable Oh My Zsh theme (using Starship instead)
ZSH_THEME=""

# Minimal essential plugins
plugins=(
  command-not-found      # Suggests package to install
  zsh-autosuggestions   # Fish-like autosuggestions
  fast-syntax-highlighting # Fast syntax highlighting (load last)
)

# Performance optimizations
DISABLE_AUTO_UPDATE="true"           # Skip auto-update checks
DISABLE_UPDATE_PROMPT="true"         # Skip update prompts
COMPLETION_WAITING_DOTS="false"      # Disable waiting dots
DISABLE_UNTRACKED_FILES_DIRTY="true" # Speed up git status in large repos

# History deduplication - speeds up autosuggestions
setopt HIST_IGNORE_ALL_DUPS  # Remove older duplicate entries from history
setopt HIST_FIND_NO_DUPS     # Don't show duplicates in search

# Completion caching - only rebuild cache once per day
autoload -Uz compinit
if [[ -n ~/.zcompdump(#qNmh+24) ]]; then
  compinit -i  # Skip security check
else
  compinit -C -i  # Use cached version, skip security check
fi

# Source Oh My Zsh
source $ZSH/oh-my-zsh.sh

# ================================
# Load Custom Modules
# ================================

# Load all custom configuration modules
for config ($HOME/dotfiles/zsh/custom/*.zsh) source $config

# Profiling - uncomment to see timing
# zprof
