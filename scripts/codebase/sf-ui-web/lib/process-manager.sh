#!/bin/bash

# process-manager.sh - Detect and manage existing sf-ui-web dev processes

LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$LIB_DIR/logging.sh"

validate_process_detection() {
    command -v pgrep >/dev/null 2>&1 && command -v lsof >/dev/null 2>&1
}

check_sf_ui_web_processes() {
    pgrep -f "sf-ui-web.*start-server\|core-funnel.*start-server\|CONFIGS_ENV=development" 2>/dev/null
}

has_sf_ui_web_processes() {
    [[ -n "$(check_sf_ui_web_processes)" ]]
}

display_sf_ui_web_processes() {
    local pids
    pids=$(check_sf_ui_web_processes)
    if [[ -n "$pids" ]]; then
        log_warning "Found existing sf-ui-web dev server processes:"
        while IFS= read -r pid; do
            local cmd
            cmd=$(ps -p "$pid" -o command= 2>/dev/null | head -c 80)
            echo "  PID $pid: $cmd"
        done <<< "$pids"
    fi
}

kill_sf_ui_web_processes() {
    local pids
    pids=$(check_sf_ui_web_processes)
    if [[ -z "$pids" ]]; then
        log_info "No existing dev server processes found"
        return 0
    fi

    display_sf_ui_web_processes
    printf "Kill existing processes? (y/n): "
    read -r response

    if [[ "$response" =~ ^[Yy]$ ]]; then
        while IFS= read -r pid; do
            kill "$pid" 2>/dev/null && log_success "Killed PID $pid" || \
                kill -9 "$pid" 2>/dev/null && log_success "Force killed PID $pid" || \
                log_warning "Could not kill PID $pid"
        done <<< "$pids"
        sleep 1
    else
        log_info "Leaving existing processes running"
    fi
}

manage_sf_ui_web_processes() {
    if has_sf_ui_web_processes; then
        kill_sf_ui_web_processes
    else
        log_info "No existing dev server processes"
    fi
    return 0
}

export -f validate_process_detection check_sf_ui_web_processes has_sf_ui_web_processes
export -f display_sf_ui_web_processes kill_sf_ui_web_processes manage_sf_ui_web_processes
