#!/bin/bash

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
# @raycast.author cc446g

# Source zshrc to get access to aliases and environment
source ~/.zshrc

# Run the cfnext command
(cd ~/codebase/codeforces && cargo run -p tools --bin next-unsolved)
