#!/bin/bash

# Claude Code Enhanced Status Line Script
# Shows project info, token usage, cache efficiency, cost, and code churn

# Read JSON input from stdin
INPUT=$(cat)

# Extract transcript path
TRANSCRIPT_PATH=$(echo "$INPUT" | grep -o '"transcript_path"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*"\([^"]*\)".*/\1/')

# Extract project directory
PROJECT_DIR=$(echo "$INPUT" | grep -o '"project_dir"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*"\([^"]*\)".*/\1/')
if [ -z "$PROJECT_DIR" ]; then
    # Fallback: try workspace.project_dir
    PROJECT_DIR=$(echo "$INPUT" | grep -o '"project_dir"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*"\([^"]*\)".*/\1/')
fi
PROJECT_NAME=$(basename "$PROJECT_DIR")

# Parse enhanced metrics using Python
METRICS=$(python3 << EOF
import json
import sys

try:
    # Parse the JSON input
    data = json.loads('''$INPUT''')

    # Extract cost data
    cost = data.get('cost', {})
    total_cost = cost.get('total_cost_usd', 0)
    lines_added = cost.get('total_lines_added', 0)
    lines_removed = cost.get('total_lines_removed', 0)

    # Calculate net lines changed
    net_lines = lines_added - lines_removed

    # Get transcript path from JSON
    transcript_path = data.get('transcript_path', '')
    if transcript_path:
        with open(transcript_path, 'r') as f:
            last_line = None
            for line in f:
                if line.strip():
                    last_line = line

            if last_line:
                entry = json.loads(last_line.strip())
                if 'message' in entry and 'usage' in entry['message']:
                    usage = entry['message']['usage']

                    # Get token counts
                    input_tokens = usage.get('input_tokens', 0)
                    cache_creation = usage.get('cache_creation_input_tokens', 0)
                    cache_read = usage.get('cache_read_input_tokens', 0)

                    # Total context
                    total_context = cache_read + cache_creation + input_tokens

                    # Cache hit rate
                    cache_rate = 0
                    if total_context > 0:
                        cache_rate = int((cache_read / total_context) * 100)

                    # Context percentage
                    context_pct = int((total_context * 100) / 200000)

                    # Format: tokens|cache_rate|cost|net_lines|context_pct
                    print(f'{total_context}|{cache_rate}|{total_cost:.3f}|{net_lines}|{context_pct}')
                else:
                    print('0|0|0.000|0|0')
            else:
                print('0|0|0.000|0|0')
    else:
        print('0|0|0.000|0|0')

except Exception as e:
    import traceback
    with open('/tmp/statusline-error.log', 'a') as f:
        f.write(f'ERROR: {str(e)}\n{traceback.format_exc()}\n')
    print('0|0|0.000|0|0')
EOF
)

# Parse the metrics
TOKENS=$(echo "$METRICS" | cut -d'|' -f1)
CACHE_RATE=$(echo "$METRICS" | cut -d'|' -f2)
COST=$(echo "$METRICS" | cut -d'|' -f3)
NET_LINES=$(echo "$METRICS" | cut -d'|' -f4)
CONTEXT_PCT=$(echo "$METRICS" | cut -d'|' -f5)

# Build status line components
STATUS_PARTS=()

# Project name
STATUS_PARTS+=("🤖 ${PROJECT_NAME}")

# Token usage with percentage
if [ "$TOKENS" -gt 0 ] 2>/dev/null; then
    TOKENS_K=$(awk "BEGIN {printf \"%.0fk\", $TOKENS / 1000}")

    # Choose emoji based on usage percentage
    if [ "$CONTEXT_PCT" -lt 50 ]; then
        ICON="📊"
    elif [ "$CONTEXT_PCT" -lt 75 ]; then
        ICON="⚡"
    else
        ICON="🔥"
    fi

    STATUS_PARTS+=("${ICON} ${TOKENS_K}/200k (${CONTEXT_PCT}%)")
fi

# Cache efficiency
if [ "$CACHE_RATE" -gt 0 ] 2>/dev/null; then
    STATUS_PARTS+=("⚡ ${CACHE_RATE}% cached")
fi

# Cost tracking
if [ "$(echo "$COST > 0" | bc -l)" -eq 1 ] 2>/dev/null; then
    STATUS_PARTS+=("💰 \$${COST}")
fi

# Code churn
if [ "$NET_LINES" -ne 0 ] 2>/dev/null; then
    if [ "$NET_LINES" -gt 0 ]; then
        STATUS_PARTS+=("±${NET_LINES} lines")
    else
        STATUS_PARTS+=("${NET_LINES} lines")
    fi
fi

# Join all parts with " | "
OUTPUT=""
for i in "${!STATUS_PARTS[@]}"; do
    if [ $i -eq 0 ]; then
        OUTPUT="${STATUS_PARTS[$i]}"
    else
        OUTPUT="${OUTPUT} | ${STATUS_PARTS[$i]}"
    fi
done

# Fallback if no data
if [ -z "$OUTPUT" ]; then
    OUTPUT="🤖 ${PROJECT_NAME} | ⏳ No data"
fi

echo "$OUTPUT"
