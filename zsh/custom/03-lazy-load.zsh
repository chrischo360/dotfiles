# Lazy Loading for Performance

# --- SDKMAN ---
sdk() {
  unfunction sdk

  if [[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]]; then
    source "$HOME/.sdkman/bin/sdkman-init.sh"
    sdk "$@"
  else
    echo "sdkman init script not found" >&2
    return 127
  fi
}

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

# --- Zoxide ---
cd() {
  if ! command -v __zoxide_z >/dev/null 2>&1; then
    eval "$(zoxide init zsh --cmd cd)"
  fi
  __zoxide_z "$@"
}
