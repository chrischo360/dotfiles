# Profiling - Use flag below to run
# ZSH_PROFILE=1 zsh 
[[ -n "$ZSH_PROFILE" ]] && zmodload zsh/zprof

# PHP 8.1 - Set as default
export PATH="/opt/homebrew/opt/php@8.1/bin:$PATH"
export PATH="/opt/homebrew/opt/php@8.1/sbin:$PATH"

# Dotfiles directory - dynamically detect location by resolving symlinks
export DOTFILES_DIR="$(cd "$(dirname "$(readlink -f "${(%):-%x}" 2>/dev/null || readlink "${(%):-%x}" 2>/dev/null || echo "${(%):-%x}")")" && cd .. && pwd)"

# Completion system
autoload -Uz compinit
compinit -C -i

# Enable prompt substitution (for git branch in prompt)
setopt PROMPT_SUBST

# Load local secrets from gitignored .env before tracked modules
if [ -f "$DOTFILES_DIR/.env" ]; then
  set -a
  source "$DOTFILES_DIR/.env"
  set +a
fi

# Load zsh plugins (from dotfiles repo)
source "$DOTFILES_DIR/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh"
source "$DOTFILES_DIR/zsh/plugins/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh"

# Load custom configuration modules
for config ($DOTFILES_DIR/zsh/custom/*.zsh); do
  source $config
done

# Deduplicate PATH (handles tmux environment inheritance)
typeset -U path

# Show profiling report if enabled
[[ -n "$ZSH_PROFILE" ]] && zprof
export PATH="/opt/homebrew/opt/libpq/bin:$PATH"
