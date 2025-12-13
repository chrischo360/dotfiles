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
  gcloud "$@"
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

# Always load NVM at startup to ensure npm globals are available for tools like ccstatusline
_load_nvm

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

# --- Zoxide ---
cd() {
  if ! command -v __zoxide_z >/dev/null 2>&1; then
    eval "$(zoxide init zsh --cmd cd)"
  fi
  __zoxide_z "$@"
}
