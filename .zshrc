# PHP 8.1 - Set as default
export PATH="/opt/homebrew/opt/php@8.1/bin:$PATH"
export PATH="/opt/homebrew/opt/php@8.1/sbin:$PATH"

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

# --- NVM (Node Version Manager) - Direct Loading ---
export NVM_DIR="$HOME/.nvm"

# Load NVM immediately at startup
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

# --- Automatic nvm version switching ---
autoload -U add-zsh-hook

load-nvmrc() {
  # Only proceed if we're in a directory with .nvmrc or package.json
  if [[ ! -f "$(pwd)/.nvmrc" && ! -f "$(pwd)/package.json" ]]; then
    return
  fi
  
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

# --- RNDR_VM --- 
export RNDR_VM="ext_ccho_wayfair_com@webphp-php8ccho-dsm1.us-central1-c.c.wf-gcp-us-sds-prod.internal"

# --- Windsurf ---
export PATH="/Users/cc446g/.codeium/windsurf/bin:$PATH"

# --- Performance: Reduce history file operations ---
HISTSIZE=1000
SAVEHIST=1000
export PATH="$HOME/.composer/vendor/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"
export NODE_EXTRA_CA_CERTS=~/certificates/wayfair-certs.pem

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
export DISABLE_PROMPT_CACHING=
export ANTHROPIC_MODEL='claude-sonnet-4-5@20250929'
# export ANTHROPIC_MODEL='claude-opus-4-1@20250805' # Opus
export ANTHROPIC_SMALL_FAST_MODEL='claude-3-5-haiku@20241022'

# --- End Claude Code Configuration ---
