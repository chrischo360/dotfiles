#!/usr/bin/env bash
set -euo pipefail

export PATH="$HOME/.local/share/mise/shims:$HOME/.local/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"

TMUX_BIN="${TMUX_BIN:-$(command -v tmux)}"
NVIM_BIN="${NVIM_BIN:-$HOME/.local/share/mise/shims/nvim}"
SHELL_BIN="${SHELL_BIN:-/bin/zsh}"

sessions=(
  "android|$HOME/codebase/wayfair-android|shell"
  "anki-goat|$HOME/anki-goat|shell"
  "basket-service|$HOME/codebase/basket-service|shell"
  "block-builder-api|$HOME/codebase/block-builder-api|shell"
  "cf-cypress|$HOME/codebase/CF-Cypress/playwright/loyalty|shell"
  "dotfiles|$HOME/dotfiles|nvim,shell"
  "experience-decision-engine|$HOME/codebase/experience-decision-engine|shell"
  "homebase|$HOME/codebase/homebase|shell"
  "ios|$HOME/Wayfair/Int_Repo/wayfair-ios|shell"
  "lacuna|$HOME/codebase/lacuna|shell"
  "leetcode|$HOME/notes/Leetcode|shell"
  "loyalty-membership|$HOME/codebase/loyalty-membership|shell"
  "loyalty-membership-subgraph|$HOME/codebase/loyalty-membership-subgraph|shell"
  "loyalty-orchestrator-subgraph|$HOME/codebase/loyalty-orchestrator-subgraph|shell"
  "music|$HOME/Music|shell"
  "notes|$HOME/notes|nvim,shell"
  "payments-paykit-subgraph|$HOME/codebase/payments-paykit-subgraph|shell"
  "php|$HOME/codebase/php|shell"
  "portfolio|$HOME/codebase/portfolio|shell"
  "server|$HOME/server|shell"
  "sf-js-libraries|$HOME/codebase/sf-js-libraries|shell"
  "sf-ui-cart-and-checkout|$HOME/codebase/sf-ui-cart-and-checkout|shell"
  "sf-ui-checkout|$HOME/codebase/sf-ui-checkout|shell"
  "sf-ui-web|$HOME/codebase/sf-ui-web|shell,shell,shell,shell"
)

command_for_mode() {
  case "$1" in
    nvim) printf '%s\n' "$NVIM_BIN" ;;
    *) printf '%s\n' "$SHELL_BIN" ;;
  esac
}

for entry in "${sessions[@]}"; do
  IFS='|' read -r name dir modes_csv <<< "$entry"

  if "$TMUX_BIN" has-session -t "$name" 2>/dev/null; then
    continue
  fi

  if [[ ! -d "$dir" ]]; then
    echo "Skipping $name: missing $dir" >&2
    continue
  fi

  IFS=',' read -r -a modes <<< "$modes_csv"
  first_command=$(command_for_mode "${modes[0]}")
  "$TMUX_BIN" new-session -d -s "$name" -c "$dir" "$first_command"

  for mode in "${modes[@]:1}"; do
    command=$(command_for_mode "$mode")
    "$TMUX_BIN" split-window -t "$name:1" -c "$dir" "$command"
  done

  if [[ ${#modes[@]} -gt 1 ]]; then
    "$TMUX_BIN" select-layout -t "$name:1" tiled >/dev/null
  fi

done
