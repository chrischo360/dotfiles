# Environment Variables

# Better History Configuration
HISTFILE="$HOME/.zsh_history"
HISTSIZE=50000
SAVEHIST=50000
setopt EXTENDED_HISTORY          # Write timestamp
setopt INC_APPEND_HISTORY        # Write immediately
setopt SHARE_HISTORY             # Share between sessions
setopt HIST_IGNORE_DUPS          # Ignore duplicates
setopt HIST_IGNORE_SPACE         # Ignore commands starting with space
setopt HIST_REDUCE_BLANKS        # Remove superfluous blanks

# Node.js
export NVM_DIR="$HOME/.nvm"
export NODE_EXTRA_CA_CERTS="$HOME/certificates/wayfair-certs.pem"

# Python
export PYENV_ROOT="$HOME/.pyenv"

# Java
export SDKMAN_DIR="$HOME/.sdkman"

# Claude Code on Vertex AI
export CLAUDE_CODE_USE_VERTEX=1
export ANTHROPIC_VERTEX_PROJECT_ID=wf-gcp-us-sf-genai-pilot-sbx
export CLOUD_ML_REGION=us-east5
export ANTHROPIC_DEFAULT_OPUS_MODEL='claude-opus-4@20250514'
export ANTHROPIC_DEFAULT_SONNET_MODEL='claude-sonnet-4-5@20250929'
export ANTHROPIC_DEFAULT_HAIKU_MODEL='claude-sonnet-4-5@20250929'
export ANTHROPIC_MODEL='claude-sonnet-4-5@20250929'
export ANTHROPIC_SMALL_FAST_MODEL='claude-sonnet-4-5@20250929'
