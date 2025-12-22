#!/bin/bash

# View agent usage statistics

AGENT_LOG="$HOME/.claude/agent-usage.log"

if [[ ! -f "$AGENT_LOG" ]]; then
    echo "No agent usage data yet."
    echo "Log file: $AGENT_LOG"
    exit 0
fi

echo "=== Custom Agent Usage Statistics ==="
echo ""
echo "Total invocations:"
wc -l < "$AGENT_LOG"
echo ""
echo "Invocations by agent:"
awk -F'Agent: ' '{print $2}' "$AGENT_LOG" | awk -F' |' '{print $1}' | sort | uniq -c | sort -rn
echo ""
echo "Recent invocations (last 10):"
tail -10 "$AGENT_LOG"
echo ""
echo "Full log: $AGENT_LOG"
