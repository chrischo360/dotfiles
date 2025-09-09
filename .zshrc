# Oh My Zsh Configuration - Optimized for Speed
export ZSH="$HOME/.oh-my-zsh"

# Fast theme - robbyrussell is one of the fastest
ZSH_THEME="robbyrussell"

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

# --- NVM (Node Version Manager) - Lazy Loading ---
export NVM_DIR="$HOME/.nvm"

# Lazy load NVM to improve startup time
nvm() {
  unset -f nvm node npm npx
  # Try loading NVM from common locations
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
  
  nvm "$@"
}

# Create placeholder functions for common node commands
node() { nvm use default >/dev/null && node "$@"; }
npm() { nvm use default >/dev/null && npm "$@"; }
npx() { nvm use default >/dev/null && npx "$@"; }

# --- NODE_EXTRA_CA_CERTS ---
export NODE_EXTRA_CA_CERTS=/Users/cc446g/codebase/wayfair-certs.pem

# --- Pyenv (Homebrew installation) ---
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/shims:$PATH"
eval "$(pyenv init -)"

# --- Yarn ---
export PATH="$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:/Users/cc446g/.local/bin:$PATH"

# --- Zoxide - Lazy load ---
cd() {
  if ! command -v __zoxide_z >/dev/null 2>&1; then
    eval "$(zoxide init zsh --cmd cd)"
  fi
  __zoxide_z "$@"
}

# --- Automatic nvm version switching (disabled for speed) ---
# Uncomment if you need auto-switching, but it slows startup
# autoload -U add-zsh-hook
# load-nvmrc() {
#   local node_version="$(nvm version)"
#   local nvmrc_path="$(nvm_find_nvmrc)"
#   if [ -n "$nvmrc_path" ]; then
#     local nvmrc_node_version=$(nvm version "$(cat "${nvmrc_path}")")
#     if [ "$nvmrc_node_version" = "N/A" ]; then
#       nvm install
#     elif [ "$nvmrc_node_version" != "$node_version" ]; then
#       nvm use
#     fi
#   elif [ "$node_version" != "$(nvm version default)" ]; then
#     echo "Reverting to nvm default version"
#     nvm use default
#   fi
# }
# add-zsh-hook chpwd load-nvmrc
# load-nvmrc

# --- RNDR_VM --- 
export RNDR_VM="ext_ccho_wayfair_com@webphp-php8ccho-dsm1.us-central1-c.c.wf-gcp-us-sds-prod.internal"

# --- Windsurf ---
export PATH="/Users/cc446g/.codeium/windsurf/bin:$PATH"

# --- Performance: Reduce history file operations ---
HISTSIZE=1000
SAVEHIST=1000
export PATH="$HOME/.composer/vendor/bin:$PATH"
