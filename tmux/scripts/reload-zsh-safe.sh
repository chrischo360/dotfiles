#!/usr/bin/env bash

# Reload zsh config only in panes running idle zsh shells
# Skips panes running vim, ssh, or other interactive programs

reloaded_count=0
skipped_count=0

while IFS= read -r line; do
  pane_id=$(echo "$line" | cut -d'|' -f1)
  command=$(echo "$line" | cut -d'|' -f2)

  # Only reload if pane is running zsh (idle shell)
  if [[ "$command" == "zsh" ]]; then
    tmux send-keys -t "$pane_id" 'source ~/.zshrc' C-m
    ((reloaded_count++))
  else
    ((skipped_count++))
  fi
done < <(tmux list-panes -a -F '#{session_name}:#{window_index}.#{pane_index}|#{pane_current_command}')

echo "Reloaded $reloaded_count panes, skipped $skipped_count (running: vim, ssh, etc.)"
