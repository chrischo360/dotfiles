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

# NOTE: pyenv, rbenv, fnm, SDKMAN have been replaced by mise
# mise handles Node.js, Python, Ruby, Java version management
# Configuration: ~/dotfiles/.mise.toml

# --- SDKMAN (Java) ---
# DISABLED: Now using mise for Java/Maven/Gradle/Scala/SBT
# If you need SDKMAN, uncomment the sections below and remove mise Java tools

# _sdkman_loaded=0
#
# _load_sdkman() {
#   if [ $_sdkman_loaded -eq 1 ]; then
#     return
#   fi
#   [[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"
#   _sdkman_loaded=1
# }
#
# sdk() {
#   _load_sdkman
#   command sdk "$@"
# }
#
# java() {
#   _load_sdkman
#   unset -f java
#   command java "$@"
# }
#
# mvn() {
#   _load_sdkman
#   unset -f mvn
#   command mvn "$@"
# }
#
# gradle() {
#   _load_sdkman
#   unset -f gradle
#   command gradle "$@"
# }
#
# scala() {
#   _load_sdkman
#   unset -f scala
#   command scala "$@"
# }
#
# sbt() {
#   _load_sdkman
#   unset -f sbt
#   command sbt "$@"
# }
#
# _apply_sdkman_env() {
#   if [[ -f .sdkmanrc ]]; then
#     _load_sdkman
#     sdk env
#   fi
# }

# --- Zoxide ---
cd() {
  if ! command -v __zoxide_z >/dev/null 2>&1; then
    eval "$(zoxide init zsh --cmd cd)"
  fi
  __zoxide_z "$@"
}
