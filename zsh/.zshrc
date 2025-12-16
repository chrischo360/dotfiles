# Profiling - Use flag below to run
# ZSH_PROFILE=1 zsh 
[[ -n "$ZSH_PROFILE" ]] && zmodload zsh/zprof

# PHP 8.1 - Set as default
export PATH="/opt/homebrew/opt/php@8.1/bin:$PATH"
export PATH="/opt/homebrew/opt/php@8.1/sbin:$PATH"

# Completion system
autoload -Uz compinit
compinit -C -i

# Enable prompt substitution (for git branch in prompt)
setopt PROMPT_SUBST

# Load zsh plugins (from dotfiles repo)
source ~/dotfiles/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
source ~/dotfiles/zsh/plugins/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh

# Load custom configuration modules
for config ($HOME/dotfiles/zsh/custom/*.zsh); do
  source $config
done

# Show profiling report if enabled
[[ -n "$ZSH_PROFILE" ]] && zprof
