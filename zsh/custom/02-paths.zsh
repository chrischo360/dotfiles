# PATH Configuration

# Local binaries (includes Claude Code CLI)
export PATH="$HOME/.local/bin:$PATH"

# mise - dev tools manager (replaces fnm, pyenv, rbenv)
if command -v mise &> /dev/null; then
  eval "$(mise activate zsh)"
fi

# Yarn (for legacy yarn installations)
export PATH="$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:$PATH"

# PHP Composer
export PATH="$HOME/.composer/vendor/bin:$PATH"
