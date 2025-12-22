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
export NODE_EXTRA_CA_CERTS="$HOME/certificates/wayfair-certs.pem"

# Java (legacy SDKMAN - consider migrating to mise)
export SDKMAN_DIR="$HOME/.sdkman"
export sdk_auto_env=true
export JAVA_HOME="$HOME/.sdkman/candidates/java/current"
export PATH="$JAVA_HOME/bin:$PATH"

# Scala/Coursier
export PATH="$PATH:$HOME/Library/Application Support/Coursier/bin"
export PATH="$PATH:$HOME/Library/Caches/ScalaCli/local-repo/bin/scala-cli"

# Claude Code on Vertex AI
export CLAUDE_CODE_USE_VERTEX=1
export ANTHROPIC_VERTEX_PROJECT_ID=wf-gcp-us-sf-genai-pilot-sbx
export CLOUD_ML_REGION=us-east5

export ANTHROPIC_DEFAULT_OPUS_MODEL='claude-opus-4@20250514'
export ANTHROPIC_DEFAULT_SONNET_MODEL='claude-sonnet-4-5@20250929'
export ANTHROPIC_DEFAULT_HAIKU_MODEL='claude-sonnet-4-5@20250929'
export ANTHROPIC_MODEL='claude-sonnet-4-5@20250929'
export ANTHROPIC_SMALL_FAST_MODEL='claude-sonnet-4-5@20250929'

# Gemini CLI on Vertex AI
export GOOGLE_GENAI_USE_VERTEXAI=true
export GOOGLE_CLOUD_PROJECT=wf-gcp-us-sf-genai-pilot-sbx
export GOOGLE_CLOUD_LOCATION=us-east5

# Google Gemini AI Studio API Key
export GEMINI_API_KEY="REDACTED_GEMINI_API_KEY"

# CD PATH - codebase
export CDPATH=".:~:~/codebase"
