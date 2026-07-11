#!/usr/bin/env bash
set -euo pipefail

export PATH="$HOME/.local/share/mise/shims:$HOME/.local/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"

TMUX_BIN="${TMUX_BIN:-$(command -v tmux)}"
NVIM_BIN="${NVIM_BIN:-$HOME/.local/share/mise/shims/nvim}"
SHELL_BIN="${SHELL_BIN:-/bin/zsh}"

sessions=(
  "dotfiles|$HOME/dotfiles|nvim"
  "notes|$HOME/notes|nvim"
  "sf-ui-web|$HOME/codebase/sf-ui-web|shell"
  "sf-ui-checkout|$HOME/codebase/sf-ui-checkout|shell"
  "loyalty-orchestrator-subgraph|$HOME/codebase/loyalty-orchestrator-subgraph|shell"
)

for entry in "${sessions[@]}"; do
  IFS='|' read -r name dir mode <<< "$entry"

  if "$TMUX_BIN" has-session -t "$name" 2>/dev/null; then
    continue
  fi

  if [[ ! -d "$dir" ]]; then
    echo "Skipping $name: missing $dir" >&2
    continue
  fi

  case "$mode" in
    nvim)
      "$TMUX_BIN" new-session -d -s "$name" -c "$dir" "$NVIM_BIN"
      ;;
    *)
      "$TMUX_BIN" new-session -d -s "$name" -c "$dir" "$SHELL_BIN"
      ;;
  esac

done
