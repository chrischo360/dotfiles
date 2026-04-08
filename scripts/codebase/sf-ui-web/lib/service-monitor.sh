#!/bin/bash

# service-monitor.sh - Monitor sf-ui-web dev server startup

LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$LIB_DIR/logging.sh"

# Timeout for dev server to become ready (seconds)
readonly DEV_SERVER_TIMEOUT=300

# Success patterns for yarn dev (core-funnel normal mode)
readonly DEV_SERVER_READY_PATTERNS=(
    "Normal:: Server started on port"
    "started on port"
    "ready on"
    "listening on"
)

# Monitor a pane for any of the given patterns
monitor_pane_for_patterns() {
    local pane_index="$1"
    local timeout="$2"
    shift 2
    local patterns=("$@")

    local elapsed=0
    local pane_target="$TMUX_SESSION:1.$pane_index"

    log_waiting "Waiting for dev server to be ready (timeout: ${timeout}s)..."

    while [[ $elapsed -lt $timeout ]]; do
        local content
        content=$(tmux capture-pane -t "$pane_target" -p -S -200 2>/dev/null)

        for pattern in "${patterns[@]}"; do
            if echo "$content" | grep -q "$pattern"; then
                log_success "Dev server ready (matched: '$pattern')"
                return 0
            fi
        done

        # Check for common error patterns
        if echo "$content" | grep -qE "Error:|Cannot find module|EADDRINUSE|Failed to compile"; then
            log_error "Dev server error detected"
            echo "$content" | grep -E "Error:|Cannot find module|EADDRINUSE|Failed to compile" | tail -5
            return 1
        fi

        sleep 2
        ((elapsed += 2))

        # Progress every 30s
        if (( elapsed % 30 == 0 )); then
            log_waiting "Still waiting... ${elapsed}s elapsed"
        fi
    done

    log_warning "Dev server did not report ready within ${timeout}s — may still be starting"
    return 1
}

monitor_dev_server() {
    local pane_index="$1"
    monitor_pane_for_patterns "$pane_index" "$DEV_SERVER_TIMEOUT" "${DEV_SERVER_READY_PATTERNS[@]}"
}

export -f monitor_pane_for_patterns monitor_dev_server
