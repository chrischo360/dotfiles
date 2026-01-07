#!/bin/bash

# process-manager.sh - Process detection and management for sf-ui-checkout

# Source logging functions
LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$LIB_DIR/logging.sh"

# Check for sf-ui-checkout specific yarn processes
check_sf_checkout_processes() {
    local pids=$(pgrep -f "yarn.*watch\|yarn.*rndr\|yarn.*tunnel\|yarn.*gql" 2>/dev/null)
    local sf_checkout_pids=()
    
    if [[ -z "$pids" ]]; then
        return 0
    fi
    
    for pid in $pids; do
        # Use lsof to check working directory of each process (macOS compatible)
        local cwd=$(lsof -p "$pid" -d cwd -Fn 2>/dev/null | grep '^n' | cut -c2-)
        if [[ $? -eq 0 ]] && echo "$cwd" | grep -q "sf-ui-checkout"; then
            sf_checkout_pids+=("$pid")
        fi
    done
    
    echo "${sf_checkout_pids[@]}"
}

# Get detailed process information
get_process_info() {
    local pid="$1"
    if [[ -z "$pid" ]]; then
        return 1
    fi
    
    # Get process command and working directory
    local cmd=$(ps -p "$pid" -o command= 2>/dev/null)
    local cwd=$(lsof -p "$pid" -d cwd -Fn 2>/dev/null | grep '^n' | cut -c2-)
    
    if [[ $? -eq 0 ]]; then
        echo "PID: $pid"
        echo "Command: $cmd"
        echo "Working Directory: $cwd"
    else
        echo "Process $pid no longer exists"
        return 1
    fi
}

# Display found processes with details
display_sf_checkout_processes() {
    local pids=($(check_sf_checkout_processes))
    
    if [[ ${#pids[@]} -eq 0 ]]; then
        log_success "No sf-ui-checkout yarn processes found"
        return 0
    fi
    
    log_warning "Found ${#pids[@]} sf-ui-checkout yarn process(es):"
    for pid in "${pids[@]}"; do
        echo ""
        get_process_info "$pid"
    done
    echo ""
    
    return ${#pids[@]}
}

# Kill specific processes with confirmation
kill_sf_checkout_processes() {
    local pids=($(check_sf_checkout_processes))
    
    if [[ ${#pids[@]} -eq 0 ]]; then
        log_success "No sf-ui-checkout yarn processes to kill"
        return 0
    fi
    
    display_sf_checkout_processes
    
    log_question "Kill these ${#pids[@]} sf-ui-checkout yarn process(es)? (y/n)"
    read -r response
    
    if [[ "$response" =~ ^[Yy]$ ]]; then
        log_progress "Killing sf-ui-checkout yarn processes..."
        
        local killed_count=0
        for pid in "${pids[@]}"; do
            if kill "$pid" 2>/dev/null; then
                log_success "Killed process $pid"
                ((killed_count++))
            else
                log_warning "Failed to kill process $pid (may have already exited)"
            fi
        done
        
        # Wait a moment for processes to terminate
        sleep 2
        
        # Verify cleanup
        local remaining_pids=($(check_sf_checkout_processes))
        if [[ ${#remaining_pids[@]} -eq 0 ]]; then
            log_success "All sf-ui-checkout yarn processes cleaned up successfully"
            return 0
        else
            log_warning "${#remaining_pids[@]} process(es) still running, attempting force kill..."
            
            for pid in "${remaining_pids[@]}"; do
                if kill -9 "$pid" 2>/dev/null; then
                    log_success "Force killed process $pid"
                else
                    log_warning "Failed to force kill process $pid"
                fi
            done
            
            sleep 1
            local final_check=($(check_sf_checkout_processes))
            if [[ ${#final_check[@]} -eq 0 ]]; then
                log_success "All processes cleaned up after force kill"
                return 0
            else
                log_error "Failed to clean up ${#final_check[@]} process(es)"
                return 1
            fi
        fi
    else
        log_info "Process cleanup cancelled by user"
        return 1
    fi
}

# Check if any processes are running (non-interactive)
has_sf_checkout_processes() {
    local pids=($(check_sf_checkout_processes))
    return $([[ ${#pids[@]} -gt 0 ]])
}

# Validate process detection works correctly
validate_process_detection() {
    log_info "Validating process detection system..."
    
    # Check if lsof command exists (macOS compatible)
    if ! command -v lsof >/dev/null 2>&1; then
        log_error "lsof command not found - process detection will not work"
        return 1
    fi
    
    # Check if pgrep command exists
    if ! command -v pgrep >/dev/null 2>&1; then
        log_error "pgrep command not found - process detection will not work"
        return 1
    fi
    
    log_success "Process detection commands available (lsof, pgrep)"
    
    # Test with current processes
    local all_yarn_pids=$(pgrep -f "yarn" 2>/dev/null)
    if [[ -n "$all_yarn_pids" ]]; then
        log_info "Found $(echo $all_yarn_pids | wc -w) total yarn processes on system"
    else
        log_info "No yarn processes currently running on system"
    fi
    
    local sf_pids=($(check_sf_checkout_processes))
    log_info "Found ${#sf_pids[@]} sf-ui-checkout specific yarn processes"
    
    return 0
}

# Interactive process management
manage_sf_checkout_processes() {
    log_checking "Checking for existing sf-ui-checkout processes..."
    
    if ! validate_process_detection; then
        log_error "Process detection validation failed"
        return 1
    fi
    
    local pids=($(check_sf_checkout_processes))
    
    if [[ ${#pids[@]} -eq 0 ]]; then
        log_success "No sf-ui-checkout yarn processes found - ready to proceed"
        return 0
    else
        log_warning "Found ${#pids[@]} sf-ui-checkout yarn process(es) that may conflict"
        display_sf_checkout_processes
        
        if kill_sf_checkout_processes; then
            log_success "Process cleanup completed successfully"
            return 0
        else
            log_error "Process cleanup failed or was cancelled"
            return 1
        fi
    fi
}

# Export functions for use in other scripts
export -f check_sf_checkout_processes get_process_info display_sf_checkout_processes
export -f kill_sf_checkout_processes has_sf_checkout_processes validate_process_detection
export -f manage_sf_checkout_processes
