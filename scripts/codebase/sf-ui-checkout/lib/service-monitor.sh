#!/bin/bash

# service-monitor.sh - Service health monitoring for development environment

# Source logging functions
LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$LIB_DIR/logging.sh"

# Service success patterns (from technical specifications)
# Using original complete patterns for fuzzy matching
readonly WEBPACK_SUCCESS_PATTERN="🚀🚀🚀 Localhost asset server listening on http://localhost:8898/webpack/sf-ui-checkout"
readonly RNDR_WATCH_SUCCESS_PATTERN="[rndr]: INFO Bundles preloaded in 1 render worker (main) and server ready in"
readonly RNDR_TUNNEL_SUCCESS_PATTERN="ssh -o ServerAliveInterval=300 -NT -R 3042:localhost:3042"
readonly REALSYNC_SUCCESS_PATTERN="Remote directory /wayfair/data/codebase/ is ready"

# Similarity threshold for fuzzy matching (75% similarity required)
readonly SIMILARITY_THRESHOLD=75

# Calculate string similarity percentage using Levenshtein distance
calculate_similarity() {
    local str1="$1"
    local str2="$2"
    
    # Remove extra whitespace and convert to lowercase for comparison
    str1=$(echo "$str1" | tr -s ' ' | tr '[:upper:]' '[:lower:]')
    str2=$(echo "$str2" | tr -s ' ' | tr '[:upper:]' '[:lower:]')
    
    local len1=${#str1}
    local len2=${#str2}
    
    # Handle empty strings
    if [[ $len1 -eq 0 && $len2 -eq 0 ]]; then
        echo "100"
        return
    elif [[ $len1 -eq 0 || $len2 -eq 0 ]]; then
        echo "0"
        return
    fi
    
    # Simple similarity calculation using common substring approach
    # Count matching characters in order
    local matches=0
    local i=0
    local j=0
    
    while [[ $i -lt $len1 && $j -lt $len2 ]]; do
        if [[ "${str1:$i:1}" == "${str2:$j:1}" ]]; then
            ((matches++))
            ((i++))
            ((j++))
        else
            # Try advancing both pointers to find next match
            local found=false
            local lookahead=5  # Look ahead up to 5 characters
            
            for ((k=1; k<=lookahead && j+k<len2; k++)); do
                if [[ "${str1:$i:1}" == "${str2:$((j+k)):1}" ]]; then
                    j=$((j+k))
                    found=true
                    break
                fi
            done
            
            if [[ "$found" == "false" ]]; then
                ((i++))
            fi
        fi
    done
    
    # Calculate similarity percentage
    local max_len=$((len1 > len2 ? len1 : len2))
    local similarity=$((matches * 100 / max_len))
    
    echo "$similarity"
}

# Check if output contains pattern with fuzzy matching
fuzzy_pattern_match() {
    local output="$1"
    local pattern="$2"
    local threshold="${3:-$SIMILARITY_THRESHOLD}"
    local debug_mode="${4:-false}"
    
    # First try exact grep match (fastest)
    if echo "$output" | grep -q "$pattern"; then
        if [[ "$debug_mode" == "true" ]]; then
            log_info "Exact pattern match found!"
        fi
        return 0
    fi
    
    if [[ "$debug_mode" == "true" ]]; then
        log_info "Exact match failed, trying fuzzy matching..."
        log_info "Pattern: ${pattern:0:50}..."
        log_info "Output length: ${#output} chars"
    fi
    
    # If exact match fails, try fuzzy matching
    # Look for the pattern within a sliding window of the output
    local pattern_len=${#pattern}
    local output_len=${#output}
    local window_size=$((pattern_len * 120 / 100))  # 20% larger than pattern for minor variations
    local best_similarity=0
    local best_window=""
    
    # Slide through the output looking for similar substrings
    for ((i=0; i<=output_len-pattern_len; i+=10)); do  # Step by 10 for performance
        local window="${output:$i:$window_size}"
        local similarity=$(calculate_similarity "$window" "$pattern")
        
        if [[ "$debug_mode" == "true" && $similarity -gt $best_similarity ]]; then
            best_similarity=$similarity
            best_window="${window:0:50}..."
        fi
        
        if [[ $similarity -ge $threshold ]]; then
            log_info "Fuzzy match found (${similarity}% similarity)"
            if [[ "$debug_mode" == "true" ]]; then
                log_info "Matching window: ${window:0:100}..."
            fi
            return 0
        fi
    done
    
    if [[ "$debug_mode" == "true" ]]; then
        log_info "Best similarity found: ${best_similarity}% (threshold: ${threshold}%)"
        log_info "Best window: $best_window"
    fi
    
    return 1
}

# Service timeout configurations (in seconds)
readonly SSH_TIMEOUT=30
readonly REALSYNC_TIMEOUT=600
readonly WEBPACK_TIMEOUT=300
readonly RNDR_WATCH_TIMEOUT=60
readonly RNDR_TUNNEL_TIMEOUT=60
readonly GQL_UPDATE_TIMEOUT=60

# Monitor service output for success pattern
monitor_service_output() {
    local pane_index="$1"
    local success_pattern="$2"
    local timeout="$3"
    local service_name="$4"
    
    if [[ -z "$pane_index" || -z "$success_pattern" || -z "$timeout" || -z "$service_name" ]]; then
        log_error "monitor_service_output requires pane_index, success_pattern, timeout, and service_name"
        return 1
    fi
    
    log_waiting "Monitoring $service_name for readiness (timeout: ${timeout}s)..."
    
    local elapsed=0
    local last_output=""
    
    while [[ $elapsed -lt $timeout ]]; do
        # Get recent pane content using proper pane targeting
        local current_output=$(tmux capture-pane -t "dev-env:1.$pane_index" -p -S -20 2>/dev/null)
        
        if [[ $? -ne 0 ]]; then
            log_error "Failed to capture pane $pane_index content"
            return 1
        fi
        
        # Convert multi-line output to single line for robust pattern matching
        # This eliminates line wrapping issues that break pattern matching
        local single_line_output=$(echo "$current_output" | tr '\n' ' ' | tr -s ' ')
        
        # Check for success pattern using fuzzy matching (use global debug mode)
        if [[ "${DEBUG_MODE:-false}" == "true" ]]; then
            log_info "Debug: Checking $service_name pattern match..."
            log_info "Debug: Single-line output (first 200 chars): ${single_line_output:0:200}..."
        fi
        
        if fuzzy_pattern_match "$single_line_output" "$success_pattern" "$SIMILARITY_THRESHOLD" "${DEBUG_MODE:-false}"; then
            log_success "$service_name is ready!"
            return 0
        fi
        
        # Check for common error patterns
        if echo "$current_output" | grep -qi "error\|failed\|cannot\|unable"; then
            # Only log if this is new error output
            if [[ "$current_output" != "$last_output" ]]; then
                log_warning "$service_name may have encountered an error:"
                echo "$current_output" | tail -3
            fi
        fi
        
        last_output="$current_output"
        sleep 2
        ((elapsed += 2))
    done
    
    log_error "$service_name did not become ready within ${timeout}s"
    log_info "Last output from $service_name:"
    echo "$current_output" | tail -5
    return 1
}

# Monitor SSH connection establishment
monitor_ssh_connection() {
    local pane_index="$1"
    local timeout="${2:-$SSH_TIMEOUT}"
    
    log_waiting "Monitoring SSH connection (timeout: ${timeout}s)..."
    
    local elapsed=0
    while [[ $elapsed -lt $timeout ]]; do
        local pane_content=$(tmux capture-pane -t "dev-env:1.$pane_index" -p -S -10 2>/dev/null)
        
        # Check for successful connection indicators
        if echo "$pane_content" | grep -q "Welcome\|Last login\|$"; then
            log_success "SSH connection established"
            return 0
        fi
        
        # Check for connection errors
        if echo "$pane_content" | grep -qi "connection refused\|timeout\|permission denied\|host key verification failed"; then
            log_error "SSH connection failed:"
            echo "$pane_content" | tail -3
            return 1
        fi
        
        sleep 1
        ((elapsed++))
    done
    
    log_error "SSH connection did not establish within ${timeout}s"
    return 1
}

# Monitor realsync completion
monitor_realsync() {
    local pane_index="$1"
    local timeout="${2:-$REALSYNC_TIMEOUT}"
    
    monitor_service_output "$pane_index" "$REALSYNC_SUCCESS_PATTERN" "$timeout" "realsync"
}

# Monitor webpack dev server
monitor_webpack() {
    local pane_index="$1"
    local timeout="${2:-$WEBPACK_TIMEOUT}"
    
    monitor_service_output "$pane_index" "$WEBPACK_SUCCESS_PATTERN" "$timeout" "webpack dev server"
}

# Monitor render watch service
monitor_rndr_watch() {
    local pane_index="$1"
    local timeout="${2:-$RNDR_WATCH_TIMEOUT}"
    
    monitor_service_output "$pane_index" "$RNDR_WATCH_SUCCESS_PATTERN" "$timeout" "render watch service"
}

# Monitor render tunnel
monitor_rndr_tunnel() {
    local pane_index="$1"
    local timeout="${2:-$RNDR_TUNNEL_TIMEOUT}"
    
    monitor_service_output "$pane_index" "$RNDR_TUNNEL_SUCCESS_PATTERN" "$timeout" "render tunnel"
}

# Monitor GraphQL update (non-blocking)
monitor_gql_update() {
    local pane_index="$1"
    local timeout="${2:-$GQL_UPDATE_TIMEOUT}"
    
    log_waiting "Monitoring GraphQL update (non-blocking, timeout: ${timeout}s)..."
    
    local elapsed=0
    while [[ $elapsed -lt $timeout ]]; do
        local pane_content=$(tmux capture-pane -t "dev-env:1.$pane_index" -p -S -10 2>/dev/null)
        
        # Check for completion (success or failure)
        if echo "$pane_content" | grep -q "Done\|Finished\|Complete\|Error\|Failed"; then
            if echo "$pane_content" | grep -qi "error\|failed"; then
                log_warning "GraphQL update completed with errors (non-critical)"
                add_warning "yarn gql:update-all completed with errors"
            else
                log_success "GraphQL update completed successfully"
            fi
            return 0
        fi
        
        sleep 2
        ((elapsed += 2))
    done
    
    log_warning "GraphQL update did not complete within ${timeout}s (non-critical)"
    add_warning "yarn gql:update-all did not complete within timeout"
    return 0  # Return success since this is non-blocking
}

# Check if service is still running in pane
is_service_running() {
    local pane_index="$1"
    local service_name="$2"
    
    if [[ -z "$pane_index" || -z "$service_name" ]]; then
        log_error "is_service_running requires pane_index and service_name"
        return 1
    fi
    
    # Check if pane exists
    if ! tmux list-panes -t "dev-env:1.$pane_index" >/dev/null 2>&1; then
        log_error "Pane $pane_index does not exist"
        return 1
    fi
    
    # Get current command in pane
    local current_command=$(tmux list-panes -t "dev-env:1.$pane_index" -F "#{pane_current_command}" 2>/dev/null)
    
    # Check if it's running a relevant process (not just shell)
    if [[ "$current_command" == "zsh" || "$current_command" == "bash" || "$current_command" == "sh" ]]; then
        log_warning "$service_name appears to have stopped (shell prompt visible)"
        return 1
    fi
    
    log_info "$service_name is running ($current_command)"
    return 0
}

# Get service status summary
get_service_status() {
    local pane_index="$1"
    local service_name="$2"
    
    if is_service_running "$pane_index" "$service_name"; then
        echo "✅ $service_name: Running"
    else
        echo "❌ $service_name: Stopped"
    fi
}

# Monitor all critical services in sequence
monitor_critical_services() {
    log_progress "Phase 1: Monitoring SSH and realsync..."
    
    # Phase 1: SSH and realsync (parallel prerequisites)
    if ! monitor_ssh_connection 4; then
        log_error "SSH connection failed - cannot proceed"
        return 1
    fi
    
    if ! monitor_realsync 5; then
        log_error "Realsync failed - cannot proceed"
        return 1
    fi
    
    notify_phase_complete "Phase 1" "SSH and realsync ready"
    
    # Phase 2: Webpack dev server
    log_progress "Phase 2: Monitoring webpack dev server..."
    if ! monitor_webpack 0; then
        log_error "Webpack dev server failed - cannot proceed"
        return 1
    fi
    
    notify_phase_complete "Phase 2" "Webpack dev server ready"
    
    # Phase 3: Render services
    log_progress "Phase 3: Monitoring render services..."
    if ! monitor_rndr_watch 1; then
        log_error "Render watch service failed - cannot proceed"
        return 1
    fi
    
    if ! monitor_rndr_tunnel 2; then
        log_error "Render tunnel failed - cannot proceed"
        return 1
    fi
    
    notify_phase_complete "Phase 3" "Render services ready"
    
    # Phase 4: GraphQL update (non-blocking)
    log_progress "Phase 4: Monitoring GraphQL update (non-blocking)..."
    monitor_gql_update 3  # Always returns success
    
    log_success "All critical services are ready!"
    return 0
}

# Display service status dashboard
show_service_dashboard() {
    log_info "Service Status Dashboard:"
    echo ""
    echo "$(get_service_status 1 'Webpack Dev Server')"
    echo "$(get_service_status 2 'Render Watch')"
    echo "$(get_service_status 3 'Render Tunnel')"
    echo "$(get_service_status 4 'GraphQL Update')"
    echo "$(get_service_status 5 'SSH Connection')"
    echo "$(get_service_status 6 'Realsync')"
    echo ""
}

# Export functions for use in other scripts
export -f monitor_service_output monitor_ssh_connection monitor_realsync monitor_webpack
export -f monitor_rndr_watch monitor_rndr_tunnel monitor_gql_update is_service_running
export -f get_service_status monitor_critical_services show_service_dashboard
