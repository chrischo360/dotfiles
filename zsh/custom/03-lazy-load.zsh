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

# --- Rbenv (Ruby) ---
_rbenv_loaded=0

_load_rbenv() {
  if [ $_rbenv_loaded -eq 1 ]; then
    return
  fi
  eval "$(rbenv init - --no-rehash zsh)"
  _rbenv_loaded=1
}

rbenv() {
  _load_rbenv
  command rbenv "$@"
}

ruby() {
  _load_rbenv
  unset -f ruby
  command ruby "$@"
}

gem() {
  _load_rbenv
  unset -f gem
  command gem "$@"
}

bundle() {
  _load_rbenv
  unset -f bundle
  command bundle "$@"
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
