#!/bin/bash

# logging.sh - Core logging and notification system for dev environment setup

# Color codes for console output
if [[ -z "${RED:-}" ]]; then
    readonly RED='\033[0;31m'
    readonly GREEN='\033[0;32m'
    readonly YELLOW='\033[1;33m'
    readonly BLUE='\033[0;34m'
    readonly PURPLE='\033[0;35m'
    readonly CYAN='\033[0;36m'
    readonly WHITE='\033[1;37m'
    readonly NC='\033[0m' # No Color
fi

# Log file setup
if [[ -z "${LOG_DIR:-}" ]]; then
    # Get absolute path to script directory and create logs directory
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    readonly LOG_DIR="$script_dir/../logs/dev-env"
    readonly LOG_FILE="${LOG_DIR}/setup-$(date +%Y%m%d-%H%M%S).log"
    readonly LATEST_LOG="${LOG_DIR}/latest.log"
    
    # Ensure log directory exists with absolute path
    mkdir -p "$LOG_DIR"
    
    # Initialize log file
    echo "=== Development Environment Setup Log ===" > "$LOG_FILE"
    echo "Started: $(date)" >> "$LOG_FILE"
    echo "User: $(whoami)" >> "$LOG_FILE"
    echo "Working Directory: $(pwd)" >> "$LOG_FILE"
    echo "Git Branch: $(git branch --show-current 2>/dev/null || echo 'unknown')" >> "$LOG_FILE"
    echo "Git Commit: $(git rev-parse --short HEAD 2>/dev/null || echo 'unknown')" >> "$LOG_FILE"
    echo "=========================================" >> "$LOG_FILE"
    
    # Create symlink to latest log
    ln -sf "$(basename "$LOG_FILE")" "$LATEST_LOG" 2>/dev/null || true
    
    # Clean up old logs (keep last 10)
    find "$LOG_DIR" -name "setup-*.log" -type f | sort -r | tail -n +11 | xargs rm -f 2>/dev/null || true
fi

# Core logging functions
log_to_file() {
    local message="$1"
    echo "[$(date '+%H:%M:%S')] $message" >> "$LOG_FILE"
}

log_info() {
    local message="$1"
    echo -e "${BLUE}[ℹ️ ]${NC} $message"
    log_to_file "INFO: $message"
}

log_success() {
    local message="$1"
    echo -e "${GREEN}[✅]${NC} $message"
    log_to_file "SUCCESS: $message"
}

log_warning() {
    local message="$1"
    echo -e "${YELLOW}[⚠️ ]${NC} $message"
    log_to_file "WARNING: $message"
}

log_error() {
    local message="$1"
    echo -e "${RED}[❌]${NC} $message"
    log_to_file "ERROR: $message"
}

log_progress() {
    local message="$1"
    echo -e "${CYAN}[🚀]${NC} $message"
    log_to_file "PROGRESS: $message"
}

log_waiting() {
    local message="$1"
    echo -e "${PURPLE}[⏳]${NC} $message"
    log_to_file "WAITING: $message"
}

log_question() {
    local message="$1"
    echo -e "${YELLOW}[❓]${NC} $message"
    log_to_file "QUESTION: $message"
}

log_checking() {
    local message="$1"
    echo -e "${CYAN}[🔍]${NC} $message"
    log_to_file "CHECKING: $message"
}

log_setup() {
    local message="$1"
    echo -e "${BLUE}[🔧]${NC} $message"
    log_to_file "SETUP: $message"
}

log_web() {
    local message="$1"
    echo -e "${PURPLE}[🌐]${NC} $message"
    log_to_file "WEB: $message"
}

log_celebration() {
    local message="$1"
    echo -e "${GREEN}[🎉]${NC} $message"
    log_to_file "CELEBRATION: $message"
}

# Desktop notification function (macOS)
send_desktop_notification() {
    local title="$1"
    local message="$2"
    local sound="${3:-default}"
    
    if command -v osascript >/dev/null 2>&1; then
        osascript -e "display notification \"$message\" with title \"$title\" sound name \"$sound\""
        log_to_file "NOTIFICATION: $title - $message"
    else
        log_warning "Desktop notifications not available (osascript not found)"
    fi
}

# Enhanced notification functions for major milestones
notify_phase_complete() {
    local phase="$1"
    local message="$2"
    send_desktop_notification "Dev Setup - $phase Complete" "$message"
    log_success "$phase: $message"
}

notify_error() {
    local title="$1"
    local message="$2"
    send_desktop_notification "Dev Setup Error - $title" "$message" "Basso"
    log_error "$title: $message"
}

notify_final_success() {
    local warnings_count="${1:-0}"
    if [ "$warnings_count" -eq 0 ]; then
        send_desktop_notification "🎉 Dev Environment Ready!" "All services running successfully"
        log_celebration "Development environment ready! All services running successfully"
    else
        send_desktop_notification "⚠️ Dev Environment Ready" "$warnings_count non-critical warning(s)"
        log_celebration "Development environment ready! ($warnings_count non-critical warnings)"
    fi
}

# Progress tracking
declare -a WARNINGS=()

add_warning() {
    local warning="$1"
    WARNINGS+=("$warning")
    log_warning "$warning"
}

get_warning_count() {
    echo "${#WARNINGS[@]}"
}

list_warnings() {
    if [ ${#WARNINGS[@]} -gt 0 ]; then
        log_warning "Non-critical issues encountered:"
        for warning in "${WARNINGS[@]}"; do
            log_warning "  - $warning"
        done
    fi
}

# Cleanup function for log file
cleanup_logs() {
    echo "=========================================" >> "$LOG_FILE"
    echo "Completed: $(date)" >> "$LOG_FILE"
    echo "Final Status: $1" >> "$LOG_FILE"
    if [ ${#WARNINGS[@]} -gt 0 ]; then
        echo "Warnings:" >> "$LOG_FILE"
        for warning in "${WARNINGS[@]}"; do
            echo "  - $warning" >> "$LOG_FILE"
        done
    fi
}

# Prevent multiple sourcing (after functions are defined)
if [[ "${LOGGING_SH_LOADED:-}" == "true" ]]; then
    return 0 2>/dev/null || true
fi
export LOGGING_SH_LOADED="true"

# Export functions for use in other scripts
export -f log_info log_success log_warning log_error log_progress log_waiting
export -f log_question log_checking log_setup log_web log_celebration
export -f send_desktop_notification notify_phase_complete notify_error notify_final_success
export -f add_warning get_warning_count list_warnings cleanup_logs log_to_file
