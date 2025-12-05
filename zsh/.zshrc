# PHP 8.1 - Set as default
export PATH="/opt/homebrew/opt/php@8.1/bin:$PATH"
export PATH="/opt/homebrew/opt/php@8.1/sbin:$PATH"

# Oh My Zsh Configuration - Optimized for Speed
export ZSH="$HOME/.oh-my-zsh"

# Disable Oh My Zsh theme (using Starship instead)
ZSH_THEME=""

# Minimal essential plugins only (removed heavy ones)
plugins=(
  git                    # Essential for git completions
  zsh-autosuggestions   # Fish-like autosuggestions  
  zsh-syntax-highlighting # Syntax highlighting (load last)
)

# Performance optimizations
DISABLE_AUTO_UPDATE="true"           # Skip auto-update checks
DISABLE_UPDATE_PROMPT="true"         # Skip update prompts
COMPLETION_WAITING_DOTS="false"      # Disable waiting dots
DISABLE_UNTRACKED_FILES_DIRTY="true" # Speed up git status in large repos

# Completion caching - only rebuild cache once per day
autoload -Uz compinit
if [[ -n ~/.zcompdump(#qNmh+24) ]]; then
  compinit
else
  compinit -C  # Use cached version for faster startup
fi

# Source Oh My Zsh
source $ZSH/oh-my-zsh.sh

# ================================
# Your Custom Configuration Below
# ================================

# --- Google Cloud SDK ---
# Lazy load to improve startup time
gcloud() {
  if [ -f '/Users/cc446g/google-cloud-sdk/path.zsh.inc' ]; then
    . '/Users/cc446g/google-cloud-sdk/path.zsh.inc'
  fi
  if [ -f '/Users/cc446g/google-cloud-sdk/completion.zsh.inc' ]; then
    . '/Users/cc446g/google-cloud-sdk/completion.zsh.inc'
  fi
  unfunction gcloud  # Remove this wrapper function
  gcloud "$@"        # Call the real gcloud
}

# --- NVM (Node Version Manager) - Smart Lazy Loading ---
export NVM_DIR="$HOME/.nvm"

# Smart NVM initialization: load immediately if in Node project, otherwise lazy-load
_nvm_loaded=0

_load_nvm() {
  if [ $_nvm_loaded -eq 1 ]; then
    return
  fi

  # Load NVM
  if [ -s "$NVM_DIR/nvm.sh" ]; then
    . "$NVM_DIR/nvm.sh"
  elif [ -s "/usr/local/opt/nvm/nvm.sh" ]; then
    . "/usr/local/opt/nvm/nvm.sh"
  fi

  # Load nvm bash_completion if available
  if [ -s "$NVM_DIR/bash_completion" ]; then
    . "$NVM_DIR/bash_completion"
  elif [ -s "/usr/local/opt/nvm/etc/bash_completion" ]; then
    . "/usr/local/opt/nvm/etc/bash_completion"
  fi

  _nvm_loaded=1
}

# Check if we're in a Node project at startup
if [[ -f "$(pwd)/.nvmrc" || -f "$(pwd)/package.json" ]]; then
  _load_nvm
else
  # Lazy-load NVM via wrapper functions
  nvm() {
    _load_nvm
    nvm "$@"
  }

  node() {
    _load_nvm
    unset -f node  # Remove wrapper
    node "$@"
  }

  npm() {
    _load_nvm
    unset -f npm
    npm "$@"
  }

  npx() {
    _load_nvm
    unset -f npx
    npx "$@"
  }
fi

# --- NODE_EXTRA_CA_CERTS ---
export NODE_EXTRA_CA_CERTS="$HOME/certificates/wayfair-certs.pem"

# --- Pyenv (Homebrew installation) - Lazy Loading ---
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/shims:$PATH"

_pyenv_loaded=0

_load_pyenv() {
  if [ $_pyenv_loaded -eq 1 ]; then
    return
  fi
  eval "$(pyenv init -)"
  _pyenv_loaded=1
}

# Lazy-load pyenv
pyenv() {
  _load_pyenv
  pyenv "$@"
}

python() {
  _load_pyenv
  unset -f python
  python "$@"
}

pip() {
  _load_pyenv
  unset -f pip
  pip "$@"
}

# --- Yarn ---
export PATH="$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:/Users/cc446g/.local/bin:$PATH"

# --- Zoxide - Lazy load ---
cd() {
  if ! command -v __zoxide_z >/dev/null 2>&1; then
    eval "$(zoxide init zsh --cmd cd)"
  fi
  __zoxide_z "$@"
}

# --- Automatic nvm version switching ---
autoload -U add-zsh-hook

load-nvmrc() {
  # Only proceed if we're in a directory with .nvmrc or package.json
  if [[ ! -f "$(pwd)/.nvmrc" && ! -f "$(pwd)/package.json" ]]; then
    return
  fi

  # Ensure NVM is loaded before trying to use it
  _load_nvm

  local node_version="$(nvm version 2>/dev/null)"
  local nvmrc_path="$(nvm_find_nvmrc 2>/dev/null)"

  if [ -n "$nvmrc_path" ]; then
    local nvmrc_node_version=$(nvm version "$(cat "${nvmrc_path}")" 2>/dev/null)

    if [ "$nvmrc_node_version" = "N/A" ]; then
      echo "🔄 Installing Node version specified in .nvmrc..."
      nvm install
    elif [ "$nvmrc_node_version" != "$node_version" ]; then
      echo "🔄 Switching to Node $(cat "${nvmrc_path}") (from .nvmrc)"
      nvm use
    fi
  elif [ -f "package.json" ] && [ "$node_version" != "$(nvm version default 2>/dev/null)" ]; then
    echo "📦 No .nvmrc found, reverting to default Node version"
    nvm use default
  fi
}

# Hook to run when changing directories
add-zsh-hook chpwd load-nvmrc

# Run once when shell starts (only if in a project directory)
load-nvmrc

# --- Glean Enterprise Search ---
export GLEAN_SUBDOMAIN="wayfair"
export GLEAN_API_TOKEN="***REMOVED-SECRET***"

# --- RNDR_VM ---
export RNDR_VM="ext_ccho_wayfair_com@webphp-php8ccho-dsm1.us-central1-c.c.wf-gcp-us-sds-prod.internal"

# --- Windsurf ---
export PATH="$HOME/.codeium/windsurf/bin:$PATH"

# --- Performance: Reduce history file operations ---
HISTSIZE=1000
SAVEHIST=1000
export PATH="$HOME/.composer/vendor/bin:$PATH"

# --- Claude Code on Vertex AI Configuration ---

# Enable Vertex AI integration for Claude Code
export CLAUDE_CODE_USE_VERTEX=1

# Set your Google Cloud Project ID for Vertex AI
# IMPORTANT: Replace YOUR-PROJECT-ID with your actual GCP project ID.
export ANTHROPIC_VERTEX_PROJECT_ID=wf-gcp-us-sf-genai-pilot-sbx

# Use the global endpoint for Vertex AI.
# Note: Some models may require a specific regional endpoint.
export CLOUD_ML_REGION=us-east5

# Optional: Disable prompt caching
# export DISABLE_PROMPT_CACHING=1

# Model configuration for Vertex AI
export ANTHROPIC_DEFAULT_OPUS_MODEL='claude-opus-4@20250514'
export ANTHROPIC_DEFAULT_SONNET_MODEL='claude-sonnet-4-5@20250929'
# Haiku not available in this project - use Sonnet for fast operations
export ANTHROPIC_DEFAULT_HAIKU_MODEL='claude-sonnet-4-5@20250929'

# Primary and small/fast models (both use Sonnet since Haiku unavailable)
export ANTHROPIC_MODEL='claude-sonnet-4-5@20250929'
export ANTHROPIC_SMALL_FAST_MODEL='claude-sonnet-4-5@20250929'

# --- End Claude Code Configuration ---

# --- SDKMAN - Lazy Loading ---
export SDKMAN_DIR="$HOME/.sdkman"

_sdkman_loaded=0

_load_sdkman() {
  if [ $_sdkman_loaded -eq 1 ]; then
    return
  fi
  [[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"
  _sdkman_loaded=1
}

# Lazy-load SDKMAN for common Java tools
sdk() {
  _load_sdkman
  sdk "$@"
}

java() {
  _load_sdkman
  unset -f java
  java "$@"
}

mvn() {
  _load_sdkman
  unset -f mvn
  mvn "$@"
}

gradle() {
  _load_sdkman
  unset -f gradle
  gradle "$@"
}

# --- Starship Prompt ---
# Initialize Starship (must be at the end of .zshrc)
eval "$(starship init zsh)"

# --- Aliases ---
# Alacritty theme picker
alias at="$HOME/dotfiles/alacritty/scripts/alacritty-theme-picker.sh"

# CodeForces - Find Next Problem
alias cfnext="(cd $HOME/codebase/codeforces && cargo run -p tools --bin next-unsolved)"
alias cfnext800="cargo run --bin next-unsolved -- --level 800"
alias cfnext1200="cargo run --bin next-unsolved -- --level 1200"

# CodeForces - Progress Tracking
alias cfadd="(cd $HOME/codebase/codeforces/training && cargo run -- add)"
alias cfshow="(cd $HOME/codebase/codeforces/training && cargo run -- show)"
