# PATH Configuration

# Local binaries (includes Claude Code CLI and mise binary)
# MUST come before mise activation so mise can be found
export PATH="$HOME/.local/bin:$PATH"

# mise - dev tools manager (replaces fnm, pyenv, rbenv)
# Use ~/.local/bin (tilde expands properly in zsh)
eval "$(~/.local/bin/mise activate zsh)"

# mise shims - Add explicitly to ensure tools are found before Homebrew
# This ensures mise-managed tools take priority over Homebrew
export PATH="$HOME/.local/share/mise/shims:$PATH"

# Yarn (for legacy yarn installations)
export PATH="$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:$PATH"

# PHP Composer
export PATH="$HOME/.composer/vendor/bin:$PATH"
