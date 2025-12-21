#!/bin/zsh

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title CF Next Problem
# @raycast.mode fullOutput
# @raycast.packageName Codeforces
# @raycast.icon 🎯

# Optional parameters:
# @raycast.needsConfirmation false

# Documentation:
# @raycast.description Find the next unsolved CodeForces problem
# @raycast.author ${RAYCAST_AUTHOR:-cc446g}

# Run the cfnext command (zsh will load .zshrc automatically in interactive mode)
cd ~/codebase/codeforces && cargo run -p tools --bin next-unsolved
