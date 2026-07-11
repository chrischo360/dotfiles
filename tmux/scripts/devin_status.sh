#!/bin/bash
# Display Devin session status for tmux statusline.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null && pwd)"
exec "$SCRIPT_DIR/agent_status.sh" "D" "$HOME/.devin/session-state.json"
