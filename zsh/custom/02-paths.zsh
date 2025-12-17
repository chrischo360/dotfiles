# PATH Configuration

# Local binaries (includes Claude Code CLI)
export PATH="$HOME/.local/bin:$PATH"

# FNM default node version (fast, adds to PATH before lazy loading)
# This ensures Node is available for tools like neovim LSP
if command -v fnm &> /dev/null; then
  FNM_DIR="${FNM_DIR:-$HOME/.local/share/fnm}"
  if [ -d "$FNM_DIR" ]; then
    # Get the default alias path (symlink points to installation dir)
    if [ -L "$FNM_DIR/aliases/default" ]; then
      NODE_INSTALLATION=$(readlink "$FNM_DIR/aliases/default")
    elif [ -L "$FNM_DIR/aliases/lts-latest" ]; then
      NODE_INSTALLATION=$(readlink "$FNM_DIR/aliases/lts-latest")
    elif [ -d "$FNM_DIR/node-versions" ]; then
      # Fallback: get latest installed version
      LATEST_VERSION=$(ls "$FNM_DIR/node-versions" | sort -V | tail -n 1)
      NODE_INSTALLATION="$FNM_DIR/node-versions/$LATEST_VERSION/installation"
    fi

    if [ -n "$NODE_INSTALLATION" ] && [ -d "$NODE_INSTALLATION/bin" ]; then
      export PATH="$NODE_INSTALLATION/bin:$PATH"
    fi
  fi
fi

# Python
export PATH="$PYENV_ROOT/shims:$PATH"

# Yarn
export PATH="$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:$PATH"

# PHP Composer
export PATH="$HOME/.composer/vendor/bin:$PATH"
