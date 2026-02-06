#!/bin/bash

# setup-dev-env.sh - Main development environment setup script
# 
# This script automates the complete setup of the sf-ui-cart-and-checkout development environment
# including tmux session management, process monitoring, remote sync, SSH connections,
# and automated cart verification via web automation.

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Get script directory and source all helper libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source all helper libraries
source "$SCRIPT_DIR/lib/logging.sh"
source "$SCRIPT_DIR/lib/process-manager.sh"
source "$SCRIPT_DIR/lib/tmux-helpers.sh"
source "$SCRIPT_DIR/lib/service-monitor.sh"
source "$SCRIPT_DIR/lib/web-automation.sh"

# Change to the sf-ui-cart-and-checkout directory for all operations
cd "$HOME/codebase/sf-ui-cart-and-checkout"

# Configuration
readonly SF_CART_DIR="$HOME/codebase/sf-ui-cart-and-checkout"
readonly TMUX_SESSION="dev-env"

# URL presets
readonly URL_CART_SIMPLE="https://wayfaircom.csnzoo.com/v/checkout/basket/show"
readonly URL_CART_WEBPACK="https://wayfaircom.csnzoo.com/v/checkout/basket/show?ft_override_enable_webpack_cart=ON&ft_override_enable_webpack_cart_ssr=ON&webpack-localhost-apps[]=sf-ui-cart-and-checkout&devbox=sde-php8ccho"

# Global debug mode flag (can be set via CLI)
DEBUG_MODE=false

# Browser selection (can be set via CLI)
BROWSER_CHOICE=""

# Chrome installation flag (can be set via CLI)
INSTALL_CHROME=false

# Chromium installation flag (can be set via CLI)
INSTALL_CHROMIUM=false

# URL selection (can be set via CLI)
CUSTOM_URL=""
USE_WEBPACK_URL=false


# Pane assignments for services (1-based indexing with pane-base-index 1)
readonly PANE_WEBPACK=1
readonly PANE_RNDR_WATCH=2
readonly PANE_RNDR_TUNNEL=3
readonly PANE_GQL_UPDATE=4
readonly PANE_SSH=5
readonly PANE_REALSYNC=6

# SSH and realsync configuration
readonly SSH_HOST="ext_ccho_wayfair_com@webphp-php8ccho-dsm1.us-central1-c.c.wf-gcp-us-sds-prod.internal"
readonly REALSYNC_TARGET="~/codebase"

# Script state tracking
SETUP_START_TIME=$(date +%s)
CRITICAL_FAILURE=false

# Cleanup function for script interruption
cleanup_on_exit() {
    local exit_code=$?
    
    log_info "Cleaning up development environment setup..."
    
    # Calculate runtime
    local end_time=$(date +%s)
    local runtime=$((end_time - SETUP_START_TIME))
    
    # Cleanup logs
    if [[ $exit_code -eq 0 ]]; then
        cleanup_logs "SUCCESS (${runtime}s runtime)"
    else
        cleanup_logs "FAILED (${runtime}s runtime, exit code: $exit_code)"
    fi
    
    # Cleanup web automation if it was started
    cleanup_web_automation
    
    # If critical failure, offer to cleanup tmux session
    if [[ "$CRITICAL_FAILURE" == "true" ]]; then
        log_question "Critical failure occurred. Clean up tmux session? (y/n): "
        read -r response
        if [[ "$response" =~ ^[Yy]$ ]]; then
            cleanup_tmux_session
        fi
    fi
    
    exit $exit_code
}

# Set up signal handlers
trap cleanup_on_exit EXIT
trap 'CRITICAL_FAILURE=true; exit 1' INT TERM

# Display script header
show_header() {
    log_celebration "🚀 SF-UI-Cart-and-Checkout Development Environment Setup"
    log_info "Starting automated development environment configuration..."
    log_info "Working directory: $SF_CART_DIR"
    log_info "Tmux session: $TMUX_SESSION"
    echo ""
}

# Validate prerequisites
validate_prerequisites() {
    log_checking "Validating prerequisites..."
    
    # Check if we're in the right directory
    if [[ ! -f "package.json" ]] || [[ ! -d "src" ]]; then
        log_error "Not in sf-ui-cart-and-checkout directory. Please run from: $SF_CART_DIR"
        return 1
    fi
    
    # Validate all required tools
    local missing_tools=()
    
    if ! command -v yarn >/dev/null 2>&1; then
        missing_tools+=("yarn")
    fi
    
    if ! command -v ssh >/dev/null 2>&1; then
        missing_tools+=("ssh")
    fi
    
    if ! command -v realsync >/dev/null 2>&1; then
        missing_tools+=("realsync")
    fi
    
    if ! validate_tmux; then
        missing_tools+=("tmux")
    fi
    
    if ! validate_process_detection; then
        missing_tools+=("process detection (lsof/pgrep)")
    fi
    
    if [[ ${#missing_tools[@]} -gt 0 ]]; then
        log_error "Missing required tools: ${missing_tools[*]}"
        log_error "Please install missing tools and try again"
        return 1
    fi
    
    log_success "All prerequisites validated"
    return 0
}

# Phase 1: Process and session management
setup_process_management() {
    log_progress "Phase 1: Setting up process and session management..."
    
    # Check and cleanup existing processes
    if ! manage_sf_checkout_processes; then
        log_error "Failed to manage existing processes"
        CRITICAL_FAILURE=true
        return 1
    fi
    
    # Setup tmux session
    if ! setup_tmux_session; then
        log_error "Failed to setup tmux session"
        CRITICAL_FAILURE=true
        return 1
    fi
    
    notify_phase_complete "Phase 1" "Process and session management ready"
    return 0
}

# Phase 3: Start remote connections (SSH + realsync)
start_remote_connections() {
    log_progress "Phase 3: Starting remote connections..."
    
    # Start SSH connection
    log_setup "Starting SSH connection to $SSH_HOST..."
    send_command_to_pane $PANE_SSH "ssh $SSH_HOST"
    
    # Start realsync
    log_setup "Starting realsync to $REALSYNC_TARGET..."
    send_command_to_pane $PANE_REALSYNC "realsync $REALSYNC_TARGET"
    
    # Monitor both connections
    local ssh_success=false
    local realsync_success=false
    
    if monitor_ssh_connection $PANE_SSH; then
        ssh_success=true
    fi
    
    if monitor_realsync $PANE_REALSYNC; then
        realsync_success=true
    fi
    
    if [[ "$ssh_success" == "true" && "$realsync_success" == "true" ]]; then
        notify_phase_complete "Phase 3" "Remote connections established"
        return 0
    else
        log_error "Remote connections failed - SSH: $ssh_success, Realsync: $realsync_success"
        CRITICAL_FAILURE=true
        return 1
    fi
}

# Phase 2: Start webpack dev server
start_webpack_server() {
    log_progress "Phase 2: Starting webpack dev server..."
    
    log_setup "Starting yarn && yarn watch:wf..."
    send_command_to_pane $PANE_WEBPACK "yarn && yarn watch:wf"
    
    if monitor_webpack $PANE_WEBPACK; then
        notify_phase_complete "Phase 2" "Webpack dev server ready"
        return 0
    else
        log_error "Webpack dev server failed to start"
        CRITICAL_FAILURE=true
        return 1
    fi
}

# Phase 4: Start render services
start_render_services() {
    log_progress "Phase 4: Starting render services..."
    
    # Start render watch service
    log_setup "Starting yarn rndr:watch-wf..."
    send_command_to_pane $PANE_RNDR_WATCH "yarn rndr:watch-wf"
    
    if ! monitor_rndr_watch $PANE_RNDR_WATCH; then
        log_error "Render watch service failed to start"
        CRITICAL_FAILURE=true
        return 1
    fi
    
    # Start render tunnel (after watch is ready)
    log_setup "Starting yarn rndr:tunnel..."
    send_command_to_pane $PANE_RNDR_TUNNEL "yarn rndr:tunnel"
    
    if monitor_rndr_tunnel $PANE_RNDR_TUNNEL; then
        notify_phase_complete "Phase 4" "Render services ready"
        return 0
    else
        log_error "Render tunnel failed to start"
        CRITICAL_FAILURE=true
        return 1
    fi
}

# Phase 5: Start optional services (non-blocking)
start_optional_services() {
    log_progress "Phase 5: Starting optional services..."
    
    # Start GraphQL update (non-blocking)
    log_setup "Starting yarn gql:update-all (non-blocking)..."
    send_command_to_pane $PANE_GQL_UPDATE "yarn gql:update-all"
    
    # Monitor but don't fail on timeout
    monitor_gql_update $PANE_GQL_UPDATE
    
    log_success "Optional services phase completed"
    return 0
}

# Install Chrome for testing using Puppeteer
install_chrome_for_testing() {
    log_progress "Installing Chrome for testing..."
    
    # Check if @puppeteer/browsers is available
    if ! command -v npx >/dev/null 2>&1; then
        log_error "npx not found - Chrome installation requires Node.js/npm"
        return 1
    fi
    
    # Change to a temporary directory to avoid installing in project
    local original_dir=$(pwd)
    local temp_dir=$(mktemp -d)
    cd "$temp_dir"
    
    log_setup "Installing Chrome stable via Puppeteer browsers..."
    log_info "Using temporary directory: $temp_dir"
    
    # Install Chrome using Puppeteer's browser management
    # This will install to the default location (~/.cache/puppeteer)
    if npx @puppeteer/browsers install chrome@stable; then
        log_success "Chrome for testing installed successfully"
        
        # Try to find the installed Chrome path in default Puppeteer cache
        local chrome_path=""
        if [[ -d "$HOME/.cache/puppeteer" ]]; then
            chrome_path=$(find "$HOME/.cache/puppeteer" -name "chrome" -type f -executable 2>/dev/null | head -1)
        fi
        
        if [[ -n "$chrome_path" ]]; then
            log_info "Chrome installed at: $chrome_path"
            # Update browser choice to use the installed Chrome
            if [[ "$BROWSER_CHOICE" == "chrome" || -z "$BROWSER_CHOICE" ]]; then
                BROWSER_CHOICE="$chrome_path"
                log_info "Browser choice updated to use installed Chrome"
            fi
        fi
        
        # Return to original directory and cleanup
        cd "$original_dir"
        rm -rf "$temp_dir"
        return 0
    else
        log_error "Failed to install Chrome for testing"
        add_warning "Chrome installation failed - using system browser"
        # Return to original directory and cleanup
        cd "$original_dir"
        rm -rf "$temp_dir"
        return 1
    fi
}

# Install Chromium for testing using Puppeteer
install_chromium_for_testing() {
    log_progress "Installing Chromium for testing..."
    
    # Check if @puppeteer/browsers is available
    if ! command -v npx >/dev/null 2>&1; then
        log_error "npx not found - Chromium installation requires Node.js/npm"
        return 1
    fi
    
    # Change to a temporary directory to avoid installing in project
    local original_dir=$(pwd)
    local temp_dir=$(mktemp -d)
    cd "$temp_dir"
    
    log_setup "Installing Chromium stable via Puppeteer browsers..."
    log_info "Using temporary directory: $temp_dir"
    
    # Install Chromium using Puppeteer's browser management
    # This will install to the default location (~/.cache/puppeteer)
    if npx @puppeteer/browsers install chromium@stable; then
        log_success "Chromium for testing installed successfully"
        
        # Try to find the installed Chromium path in default Puppeteer cache
        local chromium_path=""
        if [[ -d "$HOME/.cache/puppeteer" ]]; then
            chromium_path=$(find "$HOME/.cache/puppeteer" -name "chromium" -type f -executable 2>/dev/null | head -1)
        fi
        
        if [[ -n "$chromium_path" ]]; then
            log_info "Chromium installed at: $chromium_path"
            # Update browser choice to use the installed Chromium
            if [[ "$BROWSER_CHOICE" == "chromium" || -z "$BROWSER_CHOICE" ]]; then
                BROWSER_CHOICE="$chromium_path"
                log_info "Browser choice updated to use installed Chromium"
            fi
        fi
        
        # Return to original directory and cleanup
        cd "$original_dir"
        rm -rf "$temp_dir"
        return 0
    else
        log_error "Failed to install Chromium for testing"
        add_warning "Chromium installation failed - using system browser"
        # Return to original directory and cleanup
        cd "$original_dir"
        rm -rf "$temp_dir"
        return 1
    fi
}

# Phase 6: Web automation verification
verify_web_environment() {
    log_progress "Phase 6: Verifying web environment..."
    
    # Install Chrome if requested
    if [[ "$INSTALL_CHROME" == "true" ]]; then
        install_chrome_for_testing
    fi
    
    # Install Chromium if requested
    if [[ "$INSTALL_CHROMIUM" == "true" ]]; then
        install_chromium_for_testing
    fi
    
    # Wait a moment for all services to stabilize
    log_waiting "Allowing services to stabilize..."
    sleep 5
    
    # Run web automation verification
    if complete_web_verification; then
        notify_phase_complete "Phase 6" "Web environment verified"
        return 0
    else
        log_warning "Web environment verification had issues (non-critical)"
        add_warning "Web environment verification incomplete"
        return 0  # Don't fail setup for web verification issues
    fi
}

# Open URL in specified browser
open_in_browser() {
    local url="$1"
    local browser="${2:-}"
    
    if [[ -n "$browser" ]]; then
        # Try to open with specified browser
        case "$browser" in
            chrome|google-chrome)
                if command -v google-chrome >/dev/null 2>&1; then
                    google-chrome "$url" &
                    return 0
                elif command -v chrome >/dev/null 2>&1; then
                    chrome "$url" &
                    return 0
                elif command -v chromium >/dev/null 2>&1; then
                    chromium "$url" &
                    return 0
                fi
                ;;
            chromium)
                if command -v chromium >/dev/null 2>&1; then
                    chromium "$url" &
                    return 0
                elif command -v chromium-browser >/dev/null 2>&1; then
                    chromium-browser "$url" &
                    return 0
                fi
                ;;
            firefox)
                if command -v firefox >/dev/null 2>&1; then
                    firefox "$url" &
                    return 0
                fi
                ;;
            safari)
                if command -v safari >/dev/null 2>&1; then
                    safari "$url" &
                    return 0
                elif [[ "$OSTYPE" == "darwin"* ]]; then
                    open -a Safari "$url"
                    return 0
                fi
                ;;
            edge|microsoft-edge)
                if command -v microsoft-edge >/dev/null 2>&1; then
                    microsoft-edge "$url" &
                    return 0
                elif command -v edge >/dev/null 2>&1; then
                    edge "$url" &
                    return 0
                fi
                ;;
            brave)
                if command -v brave >/dev/null 2>&1; then
                    brave "$url" &
                    return 0
                elif command -v brave-browser >/dev/null 2>&1; then
                    brave-browser "$url" &
                    return 0
                fi
                ;;
            *)
                log_warning "Unknown browser: $browser. Trying as command..."
                if command -v "$browser" >/dev/null 2>&1; then
                    "$browser" "$url" &
                    return 0
                fi
                ;;
        esac
        
        log_warning "Could not find specified browser: $browser"
        log_info "Falling back to system default browser..."
    fi
    
    # Fall back to system default
    if command -v open >/dev/null 2>&1; then
        # macOS
        open "$url"
        return 0
    elif command -v xdg-open >/dev/null 2>&1; then
        # Linux
        xdg-open "$url"
        return 0
    elif command -v start >/dev/null 2>&1; then
        # Windows (Git Bash/WSL)
        start "$url"
        return 0
    fi
    
    return 1
}

# Get the final URL to open based on CLI options
get_final_url() {
    # Priority: custom URL > webpack preset > simple cart URL
    if [[ -n "$CUSTOM_URL" ]]; then
        echo "$CUSTOM_URL"
    elif [[ "$USE_WEBPACK_URL" == "true" ]]; then
        echo "$URL_CART_WEBPACK"
    else
        echo "$URL_CART_SIMPLE"
    fi
}

# Display final status and instructions
show_final_status() {
    local warning_count=$(get_warning_count)
    
    echo ""
    log_celebration "🎉 Development Environment Setup Complete!"
    echo ""
    
    # Show service dashboard
    show_service_dashboard
    
    # Show important URLs
    log_info "Important URLs:"
    echo "  📦 Webpack Dev Server: http://localhost:8898/webpack/sf-ui-cart-and-checkout"
    echo "  🛒 Cart Page (simple): $URL_CART_SIMPLE"
    echo "  🛒 Cart Page (webpack): $URL_CART_WEBPACK"
    echo ""
    
    # Show tmux session info
    log_info "Tmux Session: $TMUX_SESSION"
    echo "  To attach: tmux attach-session -t $TMUX_SESSION"
    echo "  To detach: Ctrl+Space, then d"
    echo ""
    
    # Show warnings if any
    if [[ $warning_count -gt 0 ]]; then
        list_warnings
        echo ""
    fi
    
    # Calculate total runtime
    local end_time=$(date +%s)
    local total_runtime=$((end_time - SETUP_START_TIME))
    
    # Send final notification
    notify_final_success $warning_count
    
    log_celebration "Setup completed in ${total_runtime}s with $warning_count warning(s)"
    log_info "📝 Detailed logs saved to: logs/dev-env/latest.log"
    
    # Open cart page in browser if setup was successful
    if [[ "$CRITICAL_FAILURE" == "false" ]]; then
        local final_url=$(get_final_url)
        
        if [[ -n "$BROWSER_CHOICE" ]]; then
            log_web "Opening cart page in $BROWSER_CHOICE..."
        else
            log_web "Opening cart page in default browser..."
        fi
        
        log_info "URL: $final_url"
        
        if open_in_browser "$final_url" "$BROWSER_CHOICE"; then
            if [[ -n "$BROWSER_CHOICE" ]]; then
                log_success "Cart page opened in $BROWSER_CHOICE"
            else
                log_success "Cart page opened in default browser"
            fi
        else
            log_warning "Could not auto-open browser. Please manually visit:"
            echo "  $final_url"
        fi
    else
        log_info "Skipping browser opening due to setup issues"
    fi
    
    log_info "Happy coding! 🚀"
}

# Parse command line arguments
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -d|--debug)
                DEBUG_MODE=true
                log_info "Debug mode enabled"
                shift
                ;;
            -b|--browser)
                if [[ -n "${2:-}" && ! "$2" =~ ^- ]]; then
                    BROWSER_CHOICE="$2"
                    log_info "Browser set to: $BROWSER_CHOICE"
                    shift 2
                else
                    log_error "--browser requires a browser name (chrome, firefox, safari, edge, etc.)"
                    exit 1
                fi
                ;;
            -u|--url)
                if [[ -n "${2:-}" && ! "$2" =~ ^- ]]; then
                    CUSTOM_URL="$2"
                    log_info "Custom URL set: $CUSTOM_URL"
                    shift 2
                else
                    log_error "--url requires a URL"
                    exit 1
                fi
                ;;
            --webpack)
                USE_WEBPACK_URL=true
                log_info "Using webpack URL preset"
                shift
                ;;
            --install-chrome)
                INSTALL_CHROME=true
                log_info "Chrome installation enabled"
                shift
                ;;
            --install-chromium)
                INSTALL_CHROMIUM=true
                log_info "Chromium installation enabled"
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

# Show help text
show_help() {
    cat << EOF
SF-UI-Cart-and-Checkout Development Environment Setup

USAGE:
    $0 [OPTIONS]

OPTIONS:
    -d, --debug         Enable debug mode for detailed pattern matching output
    -b, --browser NAME  Specify browser to open cart page (chrome, chromium, firefox, safari, edge, brave)
    -u, --url URL       Custom URL to open on completion
    --webpack           Use webpack dev URL preset (with feature flags and devbox params)
    --install-chrome    Install Chrome for testing using Puppeteer browsers
    --install-chromium  Install Chromium for testing using Puppeteer browsers
    -h, --help          Show this help message

DESCRIPTION:
    Automates the complete setup of the sf-ui-cart-and-checkout development environment
    including tmux session management, process monitoring, remote sync, SSH
    connections, and automated cart verification.

URL OPTIONS:
    By default, opens the simple cart URL:
      $URL_CART_SIMPLE
    
    With --webpack flag, opens the webpack dev URL with feature flags:
      $URL_CART_WEBPACK
    
    With --url, you can specify any custom URL.

EXAMPLES:
    $0                          # Normal setup, opens simple cart URL
    $0 --webpack                # Setup and open cart with webpack flags
    $0 --debug                  # Setup with debug output for troubleshooting
    $0 --browser chrome         # Setup and open cart page in Chrome
    $0 --browser chromium       # Setup and open cart page in Chromium
    $0 -d -b firefox            # Debug mode with Firefox
    $0 --browser safari --debug # Safari with debug output
    $0 --install-chrome         # Install Chrome for testing and use it
    $0 --install-chromium       # Install Chromium for testing and use it
    $0 --webpack -b chrome      # Webpack URL in Chrome
    $0 --url "https://custom.url/path"  # Custom URL

BROWSER OPTIONS:
    Supported browsers: chrome, firefox, safari, edge, brave
    - chrome: Opens in Google Chrome/Chromium
    - firefox: Opens in Mozilla Firefox
    - safari: Opens in Safari (macOS only)
    - edge: Opens in Microsoft Edge
    - brave: Opens in Brave Browser
    
    If browser is not found, falls back to system default browser.

CHROME INSTALLATION:
    The --install-chrome option uses Puppeteer's browser management to install
    a consistent Chrome version for testing:
    
    - Downloads Chrome stable via: npx @puppeteer/browsers install chrome@stable
    - Installs to: ~/.cache/puppeteer/ (Puppeteer's default cache location)
    - Automatically updates browser choice to use installed Chrome
    - Ensures consistent testing environment across different machines
    - Useful for CI/CD environments or when system Chrome is outdated
    - Keeps project directory clean (no browser binaries in git)
    
    Requirements: Node.js/npm must be available for npx command

DEBUG MODE:
    When enabled, provides detailed output during service monitoring including:
    - Pattern matching similarity percentages
    - Captured output samples
    - Fuzzy matching algorithm details
    - Best matching windows found

LOG FILES:
    Setup logs are automatically saved to:
    - logs/dev-env/setup-YYYYMMDD-HHMMSS.log (timestamped)
    - logs/dev-env/latest.log (symlink to most recent)
    
    Old logs are automatically cleaned up (keeps last 10 runs).
    All logs are git-ignored and won't be committed.

EOF
}

# Main execution flow
main() {
    # Parse command line arguments first
    parse_arguments "$@"
    
    show_header
    
    # Show debug mode status
    if [[ "$DEBUG_MODE" == "true" ]]; then
        log_info "🐛 Debug mode is enabled - detailed monitoring output will be shown"
        echo ""
    fi
    
    # Show URL that will be opened
    log_info "URL to open on completion: $(get_final_url)"
    echo ""
    
    # Validate environment
    if ! validate_prerequisites; then
        exit 1
    fi
    
    # Execute setup phases in sequence
    setup_process_management || exit 1
    start_webpack_server || exit 1
    start_remote_connections || exit 1
    start_render_services || exit 1
    start_optional_services  # Non-blocking
    verify_web_environment   # Non-blocking
    
    # Show final status
    show_final_status
    
    return 0
}

# Script entry point
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
