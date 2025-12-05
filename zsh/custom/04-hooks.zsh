# Zsh Hooks

# Automatic NVM version switching on directory change
autoload -U add-zsh-hook

load-nvmrc() {
  if [[ ! -f "$(pwd)/.nvmrc" && ! -f "$(pwd)/package.json" ]]; then
    return
  fi

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

add-zsh-hook chpwd load-nvmrc
load-nvmrc
