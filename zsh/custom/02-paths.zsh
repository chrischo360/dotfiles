# PATH Configuration

# Local binaries (includes Claude Code CLI)
export PATH="$HOME/.local/bin:$PATH"

# NVM default node version (fast, no full nvm loading)
if [ -d "$NVM_DIR/versions/node" ]; then
  # Get the default version from alias or fallback to latest
  if [ -f "$NVM_DIR/alias/default" ]; then
    DEFAULT_NODE_VERSION="v$(cat "$NVM_DIR/alias/default")"
  else
    # Fallback to the first installed version
    DEFAULT_NODE_VERSION=$(ls "$NVM_DIR/versions/node" | head -n 1)
  fi

  if [ -d "$NVM_DIR/versions/node/$DEFAULT_NODE_VERSION/bin" ]; then
    export PATH="$NVM_DIR/versions/node/$DEFAULT_NODE_VERSION/bin:$PATH"
  fi
fi

# Python
export PATH="$PYENV_ROOT/shims:$PATH"

# Yarn
export PATH="$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:$PATH"

# PHP Composer
export PATH="$HOME/.composer/vendor/bin:$PATH"
