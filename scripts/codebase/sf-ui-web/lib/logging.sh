#!/bin/bash

# logging.sh - Logging and notification utilities for sf-ui-web dev environment

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Warning tracking
WARNINGS=()

# Log file path (set by main script)
LOG_FILE="${LOG_FILE:-/tmp/sf-ui-web-dev-env.log}"

log_to_file() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$LOG_FILE" 2>/dev/null || true
}

log_info() {
    echo -e "${BLUE}ℹ${NC} $*"
    log_to_file "INFO: $*"
}

log_success() {
    echo -e "${GREEN}✓${NC} $*"
    log_to_file "SUCCESS: $*"
}

log_warning() {
    echo -e "${YELLOW}⚠${NC} $*"
    log_to_file "WARNING: $*"
}

log_error() {
    echo -e "${RED}✗${NC} $*" >&2
    log_to_file "ERROR: $*"
}

log_progress() {
    echo -e "${PURPLE}▶${NC} $*"
    log_to_file "PROGRESS: $*"
}

log_waiting() {
    echo -e "${CYAN}⏳${NC} $*"
    log_to_file "WAITING: $*"
}

log_checking() {
    echo -e "${CYAN}🔍${NC} $*"
    log_to_file "CHECKING: $*"
}

log_setup() {
    echo -e "${BLUE}⚙${NC} $*"
    log_to_file "SETUP: $*"
}

log_celebration() {
    echo -e "${GREEN}$*${NC}"
    log_to_file "CELEBRATION: $*"
}

add_warning() {
    WARNINGS+=("$*")
    log_warning "$*"
}

get_warning_count() {
    echo "${#WARNINGS[@]}"
}

list_warnings() {
    if [[ ${#WARNINGS[@]} -gt 0 ]]; then
        echo -e "${YELLOW}Warnings:${NC}"
        for w in "${WARNINGS[@]}"; do
            echo -e "  ${YELLOW}⚠${NC} $w"
        done
    fi
}

send_desktop_notification() {
    local title="$1"
    local message="$2"
    local sound="${3:-default}"

    if command -v terminal-notifier >/dev/null 2>&1; then
        terminal-notifier -title "$title" -message "$message" -sound "$sound" 2>/dev/null || true
    elif command -v osascript >/dev/null 2>&1; then
        osascript -e "display notification \"$message\" with title \"$title\"" 2>/dev/null || true
    fi
}

notify_phase_complete() {
    local phase="$1"
    local message="$2"
    log_success "$phase complete: $message"
    send_desktop_notification "sf-ui-web" "$phase: $message"
}

notify_final_success() {
    local warning_count="${1:-0}"
    send_desktop_notification "sf-ui-web Dev Ready" "Dev server running. $warning_count warning(s)." "Glass"
}

cleanup_logs() {
    local status="${1:-done}"
    log_to_file "=== Setup $status ==="

    # Keep last 10 log files
    local log_dir
    log_dir="$(dirname "$LOG_FILE")"
    if [[ -d "$log_dir" ]]; then
        ls -t "$log_dir"/setup-*.log 2>/dev/null | tail -n +11 | xargs rm -f 2>/dev/null || true
    fi
}

export -f log_to_file log_info log_success log_warning log_error log_progress
export -f log_waiting log_checking log_setup log_celebration
export -f add_warning get_warning_count list_warnings
export -f send_desktop_notification notify_phase_complete notify_final_success cleanup_logs
