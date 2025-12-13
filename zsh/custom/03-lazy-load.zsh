# Lazy Loading for Performance

# --- Google Cloud SDK ---
gcloud() {
  if [ -f "$HOME/google-cloud-sdk/path.zsh.inc" ]; then
    . "$HOME/google-cloud-sdk/path.zsh.inc"
  fi
  if [ -f "$HOME/google-cloud-sdk/completion.zsh.inc" ]; then
    . "$HOME/google-cloud-sdk/completion.zsh.inc"
  fi
  unfunction gcloud
  command gcloud "$@"
}

# --- NVM (Node Version Manager) ---
_nvm_loaded=0

_load_nvm() {
  if [ $_nvm_loaded -eq 1 ]; then
    return
  fi

  if [ -s "$NVM_DIR/nvm.sh" ]; then
    . "$NVM_DIR/nvm.sh"
  elif [ -s "/usr/local/opt/nvm/nvm.sh" ]; then
    . "/usr/local/opt/nvm/nvm.sh"
  fi

  if [ -s "$NVM_DIR/bash_completion" ]; then
    . "$NVM_DIR/bash_completion"
  elif [ -s "/usr/local/opt/nvm/etc/bash_completion" ]; then
    . "/usr/local/opt/nvm/etc/bash_completion"
  fi

  _nvm_loaded=1
}

# Lazy-load wrappers for common node commands
node() {
  _load_nvm
  unfunction node
  command node "$@"
}

npm() {
  _load_nvm
  unfunction npm
  command npm "$@"
}

npx() {
  _load_nvm
  unfunction npx
  command npx "$@"
}

nvm() {
  _load_nvm
  command nvm "$@"
}

# Wrap claude command to ensure ccstatusline has node available
claude() {
  _load_nvm
  command claude "$@"
}

# --- Pyenv ---
_pyenv_loaded=0

_load_pyenv() {
  if [ $_pyenv_loaded -eq 1 ]; then
    return
  fi
  eval "$(pyenv init -)"
  _pyenv_loaded=1
}

pyenv() {
  _load_pyenv
  command pyenv "$@"
}

python() {
  _load_pyenv
  unset -f python
  command python "$@"
}

pip() {
  _load_pyenv
  unset -f pip
  command pip "$@"
}

# --- SDKMAN (Java) ---
_sdkman_loaded=0

_load_sdkman() {
  if [ $_sdkman_loaded -eq 1 ]; then
    return
  fi
  [[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"
  _sdkman_loaded=1
}

sdk() {
  _load_sdkman
  command sdk "$@"
}

java() {
  _load_sdkman
  unset -f java
  command java "$@"
}

mvn() {
  _load_sdkman
  unset -f mvn
  command mvn "$@"
}

gradle() {
  _load_sdkman
  unset -f gradle
  command gradle "$@"
}

# --- Zoxide ---
cd() {
  if ! command -v __zoxide_z >/dev/null 2>&1; then
    eval "$(zoxide init zsh --cmd cd)"
  fi
  __zoxide_z "$@"
}
