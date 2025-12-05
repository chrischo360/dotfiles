#!/bin/zsh

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title CF Show Progress
# @raycast.mode fullOutput
# @raycast.packageName Codeforces
# @raycast.icon 📊

# Optional parameters:
# @raycast.needsConfirmation false

# Documentation:
# @raycast.description Show CodeForces training progress
# @raycast.author cc446g

# Run the command
cd ~/codebase/codeforces/training && cargo run -- show
