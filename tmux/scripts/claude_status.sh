#!/bin/bash
# Display Claude session status for tmux statusline.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null && pwd)"
exec "$SCRIPT_DIR/agent_status.sh" "C" "$HOME/.claude/session-state.json"
