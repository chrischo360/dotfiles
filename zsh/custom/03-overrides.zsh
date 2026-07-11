# Environment Overrides
# This file loads AFTER mise activation (02-paths.zsh) to override mise-set variables

# Java - Override mise's JAVA_HOME management
# mise unsets/clears JAVA_HOME since Java isn't in .mise.toml
# Solution: Add our own precmd hook that always restores JAVA_HOME
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
