# PATH Configuration

# Local binaries (includes Claude Code CLI and mise binary)
# MUST come before mise activation so mise can be found
export PATH="$DOTFILES_DIR/scripts/bin:$HOME/.local/bin:$PATH"

# mise - dev tools manager (replaces fnm, pyenv, rbenv)
# Use ~/.local/bin (tilde expands properly in zsh)
eval "$(~/.local/bin/mise activate zsh)"

# Override: mise unsets JAVA_HOME since Java is managed by sdkman, not mise
# Set JAVA_HOME immediately after mise activation
export JAVA_HOME="$HOME/.sdkman/candidates/java/current"
export PATH="$JAVA_HOME/bin:$PATH"

# direnv - per-directory environment variables
eval "$(direnv hook zsh)"

# Yarn (for legacy yarn installations)
export PATH="$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:$PATH"

# PHP Composer
export PATH="$HOME/.composer/vendor/bin:$PATH"
