#!/bin/bash

# tmux-helpers.sh - Tmux session management for sf-ui-web dev environment

LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$LIB_DIR/logging.sh"

# TMUX_SESSION and SF_UI_WEB_DIR are defined in the main script

validate_tmux() {
    if ! command -v tmux >/dev/null 2>&1; then
        log_error "tmux not found"
        return 1
    fi
    log_success "tmux available"
    return 0
}

session_exists() {
    timeout 5 tmux has-session -t "$TMUX_SESSION" 2>/dev/null
}

get_session_info() {
    if session_exists; then
        local pane_count
        pane_count=$(tmux list-panes -t "$TMUX_SESSION" 2>/dev/null | wc -l)
        echo "Session: $TMUX_SESSION ($pane_count panes)"
        tmux list-panes -t "$TMUX_SESSION" -F "  Pane #{pane_index}: #{pane_current_command}" 2>/dev/null
    else
        echo "Session '$TMUX_SESSION' does not exist"
        return 1
    fi
}

create_new_session() {
    log_setup "Creating tmux session '$TMUX_SESSION'..."

    if [[ ! -d "$SF_UI_WEB_DIR" ]]; then
        log_error "Directory does not exist: $SF_UI_WEB_DIR"
        return 1
    fi

    # Create session with 2 panes:
    # Pane 1: build steps (lint, yarn, lib:build, codegen, register) — runs sequentially then exits
    # Pane 2: yarn dev (long-running)
    if ! tmux new-session -d -s "$TMUX_SESSION" -c "$SF_UI_WEB_DIR" \; \
         set-option base-index 1 \; \
         set-option pane-base-index 1; then
        log_error "Failed to create tmux session '$TMUX_SESSION'"
        return 1
    fi

    # Split vertically: pane 1 (top, build output), pane 2 (bottom, yarn dev)
    tmux split-window -v -t "$TMUX_SESSION:1.1" -c "$SF_UI_WEB_DIR/apps/core-funnel" -l 70%

    # Set pane titles
    tmux select-pane -t "$TMUX_SESSION:1.1" -T "build" 2>/dev/null || true
    tmux select-pane -t "$TMUX_SESSION:1.2" -T "yarn dev" 2>/dev/null || true

    # Focus build pane
    tmux select-pane -t "$TMUX_SESSION:1.1"

    log_success "Created tmux session '$TMUX_SESSION' with 2 panes"
    return 0
}

kill_session() {
    if session_exists; then
        tmux kill-session -t "$TMUX_SESSION" 2>/dev/null && \
            log_success "Killed session '$TMUX_SESSION'" || \
            log_error "Failed to kill session '$TMUX_SESSION'"
    fi
}

manage_existing_session() {
    log_warning "Session '$TMUX_SESSION' already exists:"
    get_session_info
    echo ""
    printf "What would you like to do? (k)ill and recreate, (a)ttach: "
    read -r response

    case "$response" in
        k|K|kill)
            kill_session && create_new_session
            ;;
        a|A|attach)
            tmux attach-session -t "$TMUX_SESSION"
            return 2
            ;;
        *)
            log_error "Invalid choice"
            return 1
            ;;
    esac
}

get_pane_target() {
    echo "$TMUX_SESSION:1.$1"
}

send_command_to_pane() {
    local pane_index="$1"
    local command="$2"

    if ! tmux has-session -t "$TMUX_SESSION" 2>/dev/null; then
        log_error "Session '$TMUX_SESSION' does not exist"
        return 1
    fi

    local pane_target
    pane_target=$(get_pane_target "$pane_index")
    log_info "→ pane $pane_index: $command"
    tmux send-keys -t "$pane_target" "$command" Enter
}

get_pane_content() {
    local pane_index="$1"
    local lines="${2:-50}"
    local pane_target
    pane_target=$(get_pane_target "$pane_index")
    tmux capture-pane -t "$pane_target" -p -S "-$lines" 2>/dev/null
}

setup_tmux_session() {
    log_checking "Setting up tmux session..."
    validate_tmux || return 1

    if session_exists; then
        manage_existing_session
        local rc=$?
        [[ $rc -eq 2 ]] && exit 0  # user attached, exit script
        return $rc
    fi

    create_new_session
}

cleanup_tmux_session() {
    tmux kill-session -t "$TMUX_SESSION" 2>/dev/null || true
    log_success "Tmux cleanup complete"
}

export -f validate_tmux session_exists get_session_info create_new_session kill_session
export -f manage_existing_session get_pane_target send_command_to_pane get_pane_content
export -f setup_tmux_session cleanup_tmux_session
