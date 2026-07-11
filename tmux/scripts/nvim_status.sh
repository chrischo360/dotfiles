#!/bin/bash

count=$(tmux list-panes -a -F '#{pane_current_command}' 2>/dev/null | awk '$0 == "nvim" { count++ } END { print count + 0 }')

echo "[NV:#[fg=green]${count}#[fg=default,bg=default]]"
