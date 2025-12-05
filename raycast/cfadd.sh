#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title CF Add Progress
# @raycast.mode fullOutput
# @raycast.packageName Codeforces
# @raycast.icon ✅

# Optional parameters:
# @raycast.needsConfirmation false

# Documentation:
# @raycast.description Add progress to CodeForces training tracker
# @raycast.author cc446g

# Source zshrc to get access to aliases and environment
source ~/.zshrc

# Run the command
(cd ~/codebase/codeforces/training && cargo run -- add)
