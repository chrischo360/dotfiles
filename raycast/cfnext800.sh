#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title CF Next Problem (800)
# @raycast.mode fullOutput
# @raycast.packageName Codeforces
# @raycast.icon 🎯

# Optional parameters:
# @raycast.needsConfirmation false

# Documentation:
# @raycast.description Find the next unsolved CodeForces problem at level 800
# @raycast.author cc446g

# Source zshrc to get access to aliases and environment
source ~/.zshrc

# Run the command
cargo run --bin next-unsolved -- --level 800
