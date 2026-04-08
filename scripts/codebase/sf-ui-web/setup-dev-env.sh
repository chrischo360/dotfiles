#!/bin/bash

# setup-dev-env.sh - sf-ui-web local development environment setup
#
# Runs sequential build steps in the current shell, then launches
# yarn dev in a dedicated tmux pane and monitors until ready.
#
# Steps:
#   Phase 1: Process cleanup + tmux session setup
#   Phase 2: yarn install
#   Phase 3: yarn turbo run build --filter="[main...HEAD]"
#   Phase 4: yarn gql:codegen + yarn gql:register
#   Phase 5: yarn dev (in tmux pane, monitored until ready)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/lib/logging.sh"
source "$SCRIPT_DIR/lib/process-manager.sh"
source "$SCRIPT_DIR/lib/tmux-helpers.sh"
source "$SCRIPT_DIR/lib/service-monitor.sh"

readonly SF_UI_WEB_DIR="$HOME/codebase/sf-ui-web"
readonly TMUX_SESSION="sf-ui-web-dev"
readonly PANE_DEV=2  # yarn dev runs in pane 2; pane 1 is used for build output display

DEBUG_MODE=false
SKIP_LINT=false
SETUP_START_TIME=$(date +%s)
CRITICAL_FAILURE=false

# Set up log file
LOG_DIR="$SCRIPT_DIR/logs/dev-env"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/setup-$(date '+%Y%m%d-%H%M%S').log"
ln -sf "$LOG_FILE" "$LOG_DIR/latest.log"
export LOG_FILE

cleanup_on_exit() {
    local exit_code=$?
    local end_time
    end_time=$(date +%s)
    local runtime=$((end_time - SETUP_START_TIME))

    if [[ $exit_code -eq 0 ]]; then
        cleanup_logs "SUCCESS (${runtime}s)"
    else
        cleanup_logs "FAILED (${runtime}s, exit code: $exit_code)"
    fi

    if [[ "$CRITICAL_FAILURE" == "true" ]]; then
        printf "Critical failure. Clean up tmux session? (y/n): "
        read -r response
        if [[ "$response" =~ ^[Yy]$ ]]; then
            cleanup_tmux_session
        fi
    fi

    exit $exit_code
}

trap cleanup_on_exit EXIT
trap 'CRITICAL_FAILURE=true; exit 1' INT TERM

show_header() {
    log_celebration "sf-ui-web Development Environment Setup"
    log_info "Working directory: $SF_UI_WEB_DIR"
    log_info "Tmux session: $TMUX_SESSION"
    echo ""
}

validate_prerequisites() {
    log_checking "Validating prerequisites..."

    if [[ ! -d "$SF_UI_WEB_DIR" ]]; then
        log_error "sf-ui-web not found at $SF_UI_WEB_DIR"
        return 1
    fi

    if [[ ! -f "$SF_UI_WEB_DIR/package.json" ]]; then
        log_error "No package.json found in $SF_UI_WEB_DIR"
        return 1
    fi

    local missing=()
    command -v yarn >/dev/null 2>&1 || missing+=("yarn")
    command -v tmux >/dev/null 2>&1 || missing+=("tmux")

    if [[ ${#missing[@]} -gt 0 ]]; then
        log_error "Missing required tools: ${missing[*]}"
        return 1
    fi

    log_success "Prerequisites OK"
    return 0
}

# Phase 1: Process cleanup + tmux session
# Phase 1: lint (runs in current shell, blocking)
run_lint() {
    if [[ "$SKIP_LINT" == "true" ]]; then
        log_info "Skipping lint (--skip-lint)"
        return 0
    fi

    log_progress "Phase 1: Running lint..."

    cd "$SF_UI_WEB_DIR"

    log_setup "yarn biome lint..."
    if ! yarn biome lint; then
        log_error "biome lint failed — fix errors before starting dev server"
        CRITICAL_FAILURE=true
        return 1
    fi

    log_setup "yarn lint..."
    if ! yarn lint; then
        log_error "lint failed — fix errors before starting dev server"
        CRITICAL_FAILURE=true
        return 1
    fi

    notify_phase_complete "Phase 1" "Lint passed"
    return 0
}

# Phase 2: session setup
setup_session() {
    log_progress "Phase 2: Session setup..."

    manage_sf_ui_web_processes || true

    if ! setup_tmux_session; then
        log_error "Failed to set up tmux session"
        CRITICAL_FAILURE=true
        return 1
    fi

    notify_phase_complete "Phase 2" "Session ready"
    return 0
}

# Phase 3: yarn install (runs in current shell, blocking)
run_install() {
    log_progress "Phase 3: Installing dependencies..."

    cd "$SF_UI_WEB_DIR"
    if ! yarn; then
        log_error "yarn install failed"
        CRITICAL_FAILURE=true
        return 1
    fi

    notify_phase_complete "Phase 3" "Dependencies installed"
    return 0
}

# Phase 4: build changed packages (runs in current shell, blocking)
run_build() {
    log_progress "Phase 4: Building changed packages..."

    cd "$SF_UI_WEB_DIR"
    if ! yarn turbo run build --filter="[main...HEAD]"; then
        log_error "Build failed"
        CRITICAL_FAILURE=true
        return 1
    fi

    notify_phase_complete "Phase 4" "Build complete"
    return 0
}

# Phase 5: codegen + register (runs in current shell, blocking)
run_codegen() {
    log_progress "Phase 5: Running GraphQL codegen and register..."

    cd "$SF_UI_WEB_DIR"

    log_setup "yarn gql:codegen..."
    if ! yarn gql:codegen; then
        log_error "gql:codegen failed"
        CRITICAL_FAILURE=true
        return 1
    fi

    log_setup "yarn gql:register..."
    if ! yarn gql:register; then
        log_error "gql:register failed"
        CRITICAL_FAILURE=true
        return 1
    fi

    notify_phase_complete "Phase 5" "GraphQL codegen complete"
    return 0
}

# Phase 6: start yarn dev in tmux pane, monitor until ready
start_dev_server() {
    log_progress "Phase 6: Starting dev server..."

    send_command_to_pane $PANE_DEV "cd $SF_UI_WEB_DIR/apps/core-funnel && yarn dev"

    if monitor_dev_server $PANE_DEV; then
        notify_phase_complete "Phase 6" "Dev server ready"
        return 0
    else
        log_warning "Dev server monitor timed out — check pane $PANE_DEV"
        add_warning "Dev server readiness not confirmed — may still be starting"
        return 0  # Non-fatal: server may still come up
    fi
}

show_final_status() {
    local warning_count
    warning_count=$(get_warning_count)
    local end_time
    end_time=$(date +%s)
    local runtime=$((end_time - SETUP_START_TIME))

    echo ""
    log_celebration "sf-ui-web Dev Environment Ready!"
    echo ""
    log_info "Dev server: http://localhost:3000"
    echo ""
    log_info "Tmux session: $TMUX_SESSION"
    echo "  Attach: tmux attach-session -t $TMUX_SESSION"
    echo "  Detach: Ctrl+Space, then d"
    echo ""

    if [[ $warning_count -gt 0 ]]; then
        list_warnings
        echo ""
    fi

    log_info "Setup completed in ${runtime}s with $warning_count warning(s)"
    log_info "Logs: $LOG_FILE"

    notify_final_success "$warning_count"

    open "https://local.wayfaircom.csnzoo.com/dev/login"
}

parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -d|--debug)
                DEBUG_MODE=true
                log_info "Debug mode enabled"
                shift
                ;;
            --skip-lint)
                SKIP_LINT=true
                log_info "Skipping lint"
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

show_help() {
    cat << EOF
sf-ui-web Development Environment Setup

USAGE:
    $0 [OPTIONS]

OPTIONS:
    -d, --debug      Enable debug output
    --skip-lint      Skip lint step
    -h, --help       Show this help

STEPS:
    1. yarn biome lint + yarn lint
    2. Session setup (process cleanup + tmux)
    3. yarn install
    4. yarn turbo run build --filter="[main...HEAD]"
    5. yarn gql:codegen + yarn gql:register
    6. yarn dev (apps/core-funnel, in tmux pane)

TMUX PANES:
    Pane 1: Build output (phases 3-5)
    Pane 2: yarn dev (long-running)

LOG FILES:
    $SCRIPT_DIR/logs/dev-env/setup-YYYYMMDD-HHMMSS.log
    $SCRIPT_DIR/logs/dev-env/latest.log

EOF
}

main() {
    parse_arguments "$@"

    show_header
    validate_prerequisites || exit 1

    run_lint || exit 1
    setup_session || exit 1
    run_install || exit 1
    run_build || exit 1
    run_codegen || exit 1
    start_dev_server

    show_final_status

    # Attach to the session so user lands in the tmux panes
    if [[ -t 1 ]]; then
        log_info "Attaching to tmux session..."
        tmux attach-session -t "$TMUX_SESSION"
    else
        log_info "Not a terminal — skipping tmux attach. Run: tmux attach-session -t $TMUX_SESSION"
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
