# Environment Overrides
# This file loads AFTER mise activation (02-paths.zsh) to override mise-set variables

# Java - Override mise's JAVA_HOME management (macOS only)
# On macOS, Java is managed by sdkman, not mise. mise unsets/clears JAVA_HOME
# on every precmd/chpwd since java isn't (effectively) in .mise.toml there.
# Solution: Add our own precmd hook that always restores JAVA_HOME.
# On Linux, Java is managed by mise directly (java = "latest" in .mise.toml),
# so this override must not run there or it will point JAVA_HOME at a
# nonexistent ~/.sdkman directory and break mise's java shims.
if [[ "$(uname -s)" == "Darwin" ]]; then
  _sdkman_java_override() {
    export JAVA_HOME="$HOME/.sdkman/candidates/java/current"
    path=("$JAVA_HOME/bin" ${path:#$JAVA_HOME/bin})
  }

  # Add to precmd_functions array (runs before each prompt)
  # Place it AFTER mise's hook (append to end of array)
  if [[ -z "${precmd_functions[(r)_sdkman_java_override]}" ]]; then
    precmd_functions+=(_sdkman_java_override)
  fi

  # Also add to chpwd_functions array (runs on directory change)
  # This is needed because mise's chpwd hook also clears JAVA_HOME
  if [[ -z "${chpwd_functions[(r)_sdkman_java_override]}" ]]; then
    chpwd_functions+=(_sdkman_java_override)
  fi

  # Also set it immediately for current shell
  export JAVA_HOME="$HOME/.sdkman/candidates/java/current"
fi
