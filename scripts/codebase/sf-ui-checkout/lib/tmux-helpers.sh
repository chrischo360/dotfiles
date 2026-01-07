#!/bin/bash

# tmux-helpers.sh - Tmux session management for development environment

# Source logging functions
LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$LIB_DIR/logging.sh"

# Configuration
# TMUX_SESSION is defined in the main script
# SF_CHECKOUT_DIR is defined in the main script

# Check if tmux is available
validate_tmux() {
    if ! command -v tmux >/dev/null 2>&1; then
        log_error "tmux command not found - session management will not work"
        return 1
    fi
    
    log_success "tmux command available"
    
    # Check tmux version with timeout to prevent hanging
    local tmux_version
    if tmux_version=$(timeout 5 tmux -V 2>/dev/null); then
        log_info "Using $tmux_version"
    else
        log_warning "Could not determine tmux version (timeout or error)"
    fi
    
    return 0
}

# Check if session exists
session_exists() {
    # Add timeout to prevent hanging on tmux commands
    timeout 5 tmux has-session -t "$TMUX_SESSION" 2>/dev/null
}

# Get session information
get_session_info() {
    if session_exists; then
        local pane_count=$(tmux list-panes -t "$TMUX_SESSION" 2>/dev/null | wc -l)
        local window_count=$(tmux list-windows -t "$TMUX_SESSION" 2>/dev/null | wc -l)
        
        echo "Session: $TMUX_SESSION"
        echo "Windows: $window_count"
        echo "Panes: $pane_count"
        
        # Show pane details
        echo "Pane layout:"
        tmux list-panes -t "$TMUX_SESSION" -F "  Pane #{pane_index}: #{pane_current_command} (#{pane_current_path})" 2>/dev/null
    else
        echo "Session '$TMUX_SESSION' does not exist"
        return 1
    fi
}

# Create new tmux session with 6 panes
create_new_session() {
    log_setup "Creating new tmux session '$TMUX_SESSION'..."
    
    # Ensure the target directory exists and is accessible
    if [[ ! -d "$SF_CHECKOUT_DIR" ]]; then
        log_error "Directory does not exist: $SF_CHECKOUT_DIR"
        return 1
    fi
    
    # Create new session with first window and set both base indexes to 1 (tmux default)
    if ! tmux new-session -d -s "$TMUX_SESSION" -c "$SF_CHECKOUT_DIR" \; \
         set-option base-index 1 \; \
         set-option pane-base-index 1; then
        log_error "Failed to create tmux session '$TMUX_SESSION'"
        log_error "This could be due to:"
        log_error "  - Tmux server issues"
        log_error "  - Session name conflicts"
        log_error "  - Directory access problems"
        return 1
    fi
    
    # Verify session was actually created (without timeout for immediate check)
    if ! tmux has-session -t "$TMUX_SESSION" 2>/dev/null; then
        log_error "Session '$TMUX_SESSION' was not created successfully"
        return 1
    fi
    
    # Create 6 panes using sequential splits with proper window.pane targeting
    # Start with 1 pane (pane 1), split to create 6 total
    # Note: Window is numbered 1, panes are numbered 1-6 with pane-base-index 1
    
    # Split horizontally to create 2 columns (panes 1, 2)
    tmux split-window -h -t "$TMUX_SESSION:1.1" -c "$SF_CHECKOUT_DIR"
    
    # Split left column vertically twice (creates panes 1, 3, then 1, 3, 4)
    tmux split-window -v -t "$TMUX_SESSION:1.1" -c "$SF_CHECKOUT_DIR"
    tmux split-window -v -t "$TMUX_SESSION:1.3" -c "$SF_CHECKOUT_DIR"
    
    # Split right column vertically twice (creates panes 2, 5, then 2, 5, 6)
    tmux split-window -v -t "$TMUX_SESSION:1.2" -c "$SF_CHECKOUT_DIR"
    tmux split-window -v -t "$TMUX_SESSION:1.5" -c "$SF_CHECKOUT_DIR"
    
    # Set pane titles for clarity (if supported)
    tmux select-pane -t "$TMUX_SESSION:1.1" -T "yarn watch:wf" 2>/dev/null || true
    tmux select-pane -t "$TMUX_SESSION:1.2" -T "yarn rndr:watch-wf" 2>/dev/null || true
    tmux select-pane -t "$TMUX_SESSION:1.3" -T "yarn rndr:tunnel" 2>/dev/null || true
    tmux select-pane -t "$TMUX_SESSION:1.4" -T "yarn gql:update-all" 2>/dev/null || true
    tmux select-pane -t "$TMUX_SESSION:1.5" -T "SSH" 2>/dev/null || true
    tmux select-pane -t "$TMUX_SESSION:1.6" -T "realsync" 2>/dev/null || true
    
    # Select first pane
    tmux select-pane -t "$TMUX_SESSION:1.1"
    
    log_success "Created tmux session '$TMUX_SESSION' with 6 panes"
    return 0
}

# Kill existing session
kill_session() {
    if session_exists; then
        log_progress "Killing existing tmux session '$TMUX_SESSION'..."
        tmux kill-session -t "$TMUX_SESSION"
        
        if [[ $? -eq 0 ]]; then
            log_success "Killed tmux session '$TMUX_SESSION'"
            return 0
        else
            log_error "Failed to kill tmux session '$TMUX_SESSION'"
            return 1
        fi
    else
        log_info "No existing session '$TMUX_SESSION' to kill"
        return 0
    fi
}

# Interactive session management
manage_existing_session() {
    log_warning "Tmux session '$TMUX_SESSION' already exists:"
    echo ""
    get_session_info
    echo ""
    
    log_question "What would you like to do? (k)ill and recreate, (r)euse existing, (a)ttach to view: "
    read -r response
    
    case "$response" in
        k|K|kill)
            if kill_session && create_new_session; then
                log_success "Session recreated successfully"
                return 0
            else
                log_error "Failed to recreate session"
                return 1
            fi
            ;;
        r|R|reuse)
            log_info "Reusing existing session '$TMUX_SESSION'"
            return 0
            ;;
        a|A|attach)
            log_info "Attaching to existing session '$TMUX_SESSION'..."
            tmux attach-session -t "$TMUX_SESSION"
            return 2  # Special return code for "attached"
            ;;
        *)
            log_error "Invalid choice. Please choose (k)ill, (r)euse, or (a)ttach"
            return 1
            ;;
    esac
}

# Get proper tmux pane target reference
get_pane_target() {
    local pane_index="$1"
    if [[ -z "$pane_index" ]]; then
        log_error "get_pane_target requires pane_index"
        return 1
    fi
    echo "$TMUX_SESSION:1.$pane_index"
}

# Send command to specific pane
send_command_to_pane() {
    local pane_index="$1"
    local command="$2"
    
    if [[ -z "$pane_index" || -z "$command" ]]; then
        log_error "send_command_to_pane requires pane_index and command"
        return 1
    fi
    
    # Use direct tmux check instead of session_exists function
    if ! tmux has-session -t "$TMUX_SESSION" 2>/dev/null; then
        log_error "Session '$TMUX_SESSION' does not exist"
        log_error "Available sessions:"
        tmux list-sessions 2>/dev/null || log_error "No tmux sessions found"
        return 1
    fi
    
    local pane_target=$(get_pane_target "$pane_index")
    log_info "Sending command to pane $pane_index: $command"
    tmux send-keys -t "$pane_target" "$command" Enter
    
    return $?
}

# Wait for command completion in pane (basic implementation)
wait_for_pane_ready() {
    local pane_index="$1"
    local timeout="${2:-30}"
    local success_pattern="${3:-}"
    
    if [[ -z "$pane_index" ]]; then
        log_error "wait_for_pane_ready requires pane_index"
        return 1
    fi
    
    log_waiting "Waiting for pane $pane_index to be ready (timeout: ${timeout}s)..."
    
    local pane_target=$(get_pane_target "$pane_index")
    local elapsed=0
    while [[ $elapsed -lt $timeout ]]; do
        # Check if pane still exists and is not running a command
        local pane_info=$(tmux list-panes -t "$pane_target" -F "#{pane_current_command}" 2>/dev/null)
        
        if [[ $? -ne 0 ]]; then
            log_error "Pane $pane_index no longer exists"
            return 1
        fi
        
        # If we have a success pattern, check for it
        if [[ -n "$success_pattern" ]]; then
            local pane_content=$(tmux capture-pane -t "$pane_target" -p 2>/dev/null)
            if echo "$pane_content" | grep -q "$success_pattern"; then
                log_success "Pane $pane_index ready (found success pattern)"
                return 0
            fi
        fi
        
        sleep 1
        ((elapsed++))
    done
    
    log_warning "Pane $pane_index did not become ready within ${timeout}s"
    return 1
}

# Get pane content for monitoring
get_pane_content() {
    local pane_index="$1"
    local lines="${2:-10}"
    
    if [[ -z "$pane_index" ]]; then
        log_error "get_pane_content requires pane_index"
        return 1
    fi
    
    if ! session_exists; then
        log_error "Session '$TMUX_SESSION' does not exist"
        return 1
    fi
    
    local pane_target=$(get_pane_target "$pane_index")
    tmux capture-pane -t "$pane_target" -p -S "-$lines" 2>/dev/null
}

# Main session setup function
setup_tmux_session() {
    log_checking "Setting up tmux session..."
    
    if ! validate_tmux; then
        return 1
    fi
    
    # More aggressive cleanup to ensure clean state
    log_info "Ensuring clean tmux session state..."
    
    # First try to kill the specific session
    tmux kill-session -t "$TMUX_SESSION" 2>/dev/null || true
    
    # If session still exists, kill the entire tmux server
    if tmux has-session -t "$TMUX_SESSION" 2>/dev/null; then
        log_warning "Session still exists, killing tmux server for clean state..."
        tmux kill-server 2>/dev/null || true
        sleep 1  # Give tmux server time to fully shutdown
    fi
    
    # Create new session
    if create_new_session; then
        log_success "Tmux session setup complete"
        return 0
    else
        log_error "Failed to create tmux session"
        return 1
    fi
}

# Cleanup function
cleanup_tmux_session() {
    log_info "Cleaning up tmux session '$TMUX_SESSION'..."
    
    # First try to kill the specific session
    tmux kill-session -t "$TMUX_SESSION" 2>/dev/null || true
    
    # If session still exists, kill the entire tmux server
    if tmux has-session -t "$TMUX_SESSION" 2>/dev/null; then
        log_warning "Session still exists, killing tmux server for complete cleanup..."
        tmux kill-server 2>/dev/null || true
    fi
    
    log_success "Tmux cleanup complete"
}

# Export functions for use in other scripts
export -f validate_tmux session_exists get_session_info create_new_session kill_session
export -f manage_existing_session send_command_to_pane wait_for_pane_ready get_pane_content
export -f setup_tmux_session cleanup_tmux_session
