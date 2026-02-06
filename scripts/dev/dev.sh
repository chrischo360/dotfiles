#!/bin/bash
# dev - Context-aware development CLI
# Usage: dev [command] [flags]

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
DIM='\033[2m'
NC='\033[0m'

# Config location
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/config.json"

# Check dependencies
if ! command -v jq &> /dev/null; then
    echo -e "${RED}Error: jq is required but not installed${NC}"
    echo "Install with: brew install jq"
    exit 1
fi

if [[ ! -f "$CONFIG_FILE" ]]; then
    echo -e "${RED}Error: Config file not found at $CONFIG_FILE${NC}"
    exit 1
fi

# ============================================================================
# Detection Functions
# ============================================================================

check_package_name() {
    local expected="$1"
    if [[ -f "package.json" ]]; then
        local actual=$(jq -r '.name // ""' package.json 2>/dev/null)
        [[ "$actual" == "$expected" ]]
    else
        return 1
    fi
}

check_file_exists() {
    local file="$1"
    [[ -f "$file" ]]
}

check_dir_exists() {
    local dir="$1"
    [[ -d "$dir" ]]
}

check_file_contains() {
    local file="$1"
    local pattern="$2"
    [[ -f "$file" ]] && grep -q "$pattern" "$file" 2>/dev/null
}

check_path_contains() {
    local pattern="$1"
    [[ "$PWD" == *"$pattern"* ]]
}

check_git_remote() {
    local pattern="$1"
    if git rev-parse --git-dir &> /dev/null; then
        git remote -v 2>/dev/null | grep -q "$pattern"
    else
        return 1
    fi
}

check_env() {
    local var="$1"
    [[ -n "${!var}" ]]
}

# Check if a single detect rule matches (AND logic for multiple keys)
check_detect_rule() {
    local rule="$1"
    local keys=$(echo "$rule" | jq -r 'keys[]')
    
    for key in $keys; do
        local value=$(echo "$rule" | jq -r ".[\"$key\"]")
        
        case "$key" in
            package_name)
                check_package_name "$value" || return 1
                ;;
            file)
                check_file_exists "$value" || return 1
                ;;
            dir)
                check_dir_exists "$value" || return 1
                ;;
            file_contains)
                # Expects {"file": "...", "contains": "..."}
                local file=$(echo "$rule" | jq -r '.file // ""')
                local contains=$(echo "$rule" | jq -r '.contains // ""')
                check_file_contains "$file" "$contains" || return 1
                ;;
            contains)
                # Skip - handled by file_contains
                ;;
            path_contains)
                check_path_contains "$value" || return 1
                ;;
            git_remote)
                check_git_remote "$value" || return 1
                ;;
            env)
                check_env "$value" || return 1
                ;;
        esac
    done
    
    return 0
}

# Check if any detect rules match (OR logic for array)
check_detect_rules() {
    local rules="$1"
    local count=$(echo "$rules" | jq 'length')
    
    for ((i=0; i<count; i++)); do
        local rule=$(echo "$rules" | jq ".[$i]")
        if check_detect_rule "$rule"; then
            return 0
        fi
    done
    
    return 1
}

# ============================================================================
# Project Detection
# ============================================================================

# Find project root by walking up directories
# For monorepos, we need to find the actual root, not subdirectories
find_project_root() {
    local project_name="$1"
    local current_dir="$PWD"
    local found_root=""
    local detect_rules=$(jq -r ".projects[\"$project_name\"].detect" "$CONFIG_FILE")
    
    # Walk up and find the topmost matching directory (true project root)
    while [[ "$current_dir" != "/" ]]; do
        pushd "$current_dir" > /dev/null 2>&1 || { popd > /dev/null 2>&1; current_dir="$(dirname "$current_dir")"; continue; }
        if check_detect_rules "$detect_rules"; then
            found_root="$current_dir"
        fi
        popd > /dev/null 2>&1
        current_dir="$(dirname "$current_dir")"
    done
    
    if [[ -n "$found_root" ]]; then
        echo "$found_root"
        return 0
    fi
    
    return 1
}

# Detect which project we're in
detect_project() {
    local projects=$(jq -r '.projects | keys[]' "$CONFIG_FILE")
    
    for project in $projects; do
        local detect_rules=$(jq -r ".projects[\"$project\"].detect" "$CONFIG_FILE")
        
        # Check current directory first
        if check_detect_rules "$detect_rules"; then
            echo "$project"
            return 0
        fi
        
        # Check if we're in a subdirectory of the project
        local root=$(find_project_root "$project" 2>/dev/null)
        if [[ -n "$root" ]]; then
            echo "$project"
            return 0
        fi
    done
    
    # Fall back to defaults
    local defaults=$(jq -r '.defaults | keys[]' "$CONFIG_FILE")
    for default in $defaults; do
        local detect_rules=$(jq -r ".defaults[\"$default\"].detect" "$CONFIG_FILE")
        if check_detect_rules "$detect_rules"; then
            echo "default:$default"
            return 0
        fi
    done
    
    return 1
}

# Get relative path from project root
get_relative_path() {
    local project_root="$1"
    local rel_path="${PWD#$project_root}"
    rel_path="${rel_path#/}"  # Remove leading slash
    echo "$rel_path"
}

# ============================================================================
# Context Resolution
# ============================================================================

# Find matching context for current directory
find_context() {
    local project="$1"
    local rel_path="$2"
    local contexts=$(jq -r ".projects[\"$project\"].contexts | keys[]" "$CONFIG_FILE" 2>/dev/null)
    
    # Empty rel_path means we're at root
    [[ -z "$rel_path" ]] && rel_path="/"
    
    # First try exact match
    for ctx in $contexts; do
        if [[ "$ctx" == "/" && "$rel_path" == "/" ]]; then
            echo "/"
            return 0
        elif [[ "$ctx" != "/" && "$rel_path" == "$ctx"* ]]; then
            echo "$ctx"
            return 0
        fi
    done
    
    # Try glob patterns (e.g., packages/*)
    for ctx in $contexts; do
        if [[ "$ctx" == *"*"* ]]; then
            local pattern="${ctx//\*/.*}"
            if [[ "$rel_path" =~ ^$pattern ]]; then
                echo "$ctx"
                return 0
            fi
        fi
    done
    
    # Fall back to root context
    echo "/"
}

# Get command for context (with inheritance from root)
get_command() {
    local project="$1"
    local context="$2"
    local cmd="$3"
    
    # Check if it's a default project type
    if [[ "$project" == default:* ]]; then
        local default_type="${project#default:}"
        local result=$(jq -r ".defaults[\"$default_type\"].commands[\"$cmd\"] // \"\"" "$CONFIG_FILE")
        echo "$result"
        return
    fi
    
    # Try context-specific command first
    local result=$(jq -r ".projects[\"$project\"].contexts[\"$context\"][\"$cmd\"] // \"\"" "$CONFIG_FILE")
    
    # Fall back to root context if not found
    if [[ -z "$result" && "$context" != "/" ]]; then
        result=$(jq -r ".projects[\"$project\"].contexts[\"/\"][\"$cmd\"] // \"\"" "$CONFIG_FILE")
    fi
    
    echo "$result"
}

# List available commands for context
list_commands() {
    local project="$1"
    local context="$2"
    
    if [[ "$project" == default:* ]]; then
        local default_type="${project#default:}"
        jq -r ".defaults[\"$default_type\"].commands | keys[]" "$CONFIG_FILE" 2>/dev/null
        return
    fi
    
    # Get context-specific commands (handle keys with spaces)
    local ctx_cmds=$(jq -r ".projects[\"$project\"].contexts[\"$context\"] // {} | keys | .[]" "$CONFIG_FILE" 2>/dev/null)
    
    # Get root commands (for inheritance)
    local root_cmds=""
    if [[ "$context" != "/" ]]; then
        root_cmds=$(jq -r ".projects[\"$project\"].contexts[\"/\"] // {} | keys | .[]" "$CONFIG_FILE" 2>/dev/null)
    fi
    
    # Combine and deduplicate
    { echo "$ctx_cmds"; echo "$root_cmds"; } | sort -u | grep -v '^$'
}

# ============================================================================
# Display Functions
# ============================================================================

show_help() {
    echo -e "${BLUE}dev${NC} - Context-aware development CLI"
    echo ""
    echo -e "${YELLOW}USAGE:${NC}"
    echo "    dev [command] [flags]"
    echo "    dev :list              List available commands"
    echo "    dev :scripts           List available scripts"
    echo "    dev :run <script>      Run a multi-step script"
    echo "    dev :info              Show detected project info"
    echo "    dev :docs              Show LLM-friendly documentation"
    echo "    dev :config            Open config file"
    echo "    dev :root <cmd>        Run command from project root"
    echo ""
    echo -e "${YELLOW}EXAMPLES:${NC}"
    echo "    dev start              Start dev server"
    echo "    dev build              Build project"
    echo "    dev rebuild            Quick rebuild (codegen + build)"
    echo "    dev clean              Clean build artifacts"
    echo "    dev clean:all          Clean everything"
    echo "    dev :root build        Run build from project root"
    echo "    dev :run setup         Run multi-step setup script"
    echo ""
    echo -e "${YELLOW}CONFIG:${NC}"
    echo "    $CONFIG_FILE"
}

show_info() {
    local project="$1"
    local context="$2"
    local project_root="$3"
    
    echo -e "${BLUE}Project:${NC}  $project"
    echo -e "${BLUE}Root:${NC}     $project_root"
    echo -e "${BLUE}Context:${NC}  $context"
    echo -e "${BLUE}PWD:${NC}      $PWD"
    echo ""
    echo -e "${YELLOW}Available commands:${NC}"
    
    list_commands "$project" "$context" | while IFS= read -r cmd; do
        [[ -z "$cmd" ]] && continue
        local full_cmd=$(get_command "$project" "$context" "$cmd")
        echo -e "  ${GREEN}$cmd${NC} ${DIM}→ $full_cmd${NC}"
    done
}

show_commands() {
    local project="$1"
    local context="$2"
    
    echo -e "${YELLOW}Available commands for ${BLUE}$project${NC} ${DIM}(context: $context)${NC}:"
    echo ""
    
    list_commands "$project" "$context" | while IFS= read -r cmd; do
        [[ -z "$cmd" ]] && continue
        local full_cmd=$(get_command "$project" "$context" "$cmd")
        printf "  ${GREEN}%-16s${NC} %s\n" "$cmd" "$full_cmd"
    done
}

# ============================================================================
# Notification Functions
# ============================================================================

# Send macOS notification
send_notification() {
    local title="$1"
    local message="$2"
    local status="$3"  # success or failure
    
    # Check if notifications are enabled
    local notify_enabled=$(jq -r '.settings.notifications // false' "$CONFIG_FILE")
    [[ "$notify_enabled" != "true" ]] && return
    
    # Check if this status should notify
    local notify_on=$(jq -r '.settings.notify_on // ["success", "failure"] | .[]' "$CONFIG_FILE")
    if ! echo "$notify_on" | grep -q "$status"; then
        return
    fi
    
    # Use terminal-notifier if available
    if command -v terminal-notifier &> /dev/null; then
        local sound=$(jq -r '.settings.sound // "default"' "$CONFIG_FILE")
        local icon="✅"
        [[ "$status" == "failure" ]] && icon="❌"
        
        terminal-notifier \
            -title "dev: $title" \
            -message "$icon $message" \
            -sound "$sound" \
            -group "dev-cli" \
            2>/dev/null
    elif command -v osascript &> /dev/null; then
        # Fallback to osascript
        osascript -e "display notification \"$message\" with title \"dev: $title\"" 2>/dev/null
    fi
}

# ============================================================================
# Script Functions
# ============================================================================

# List available scripts for project (including global)
list_scripts() {
    local project="$1"
    
    if [[ "$project" == default:* ]]; then
        return
    fi
    
    # Get project scripts
    local project_scripts=$(jq -r ".projects[\"$project\"].scripts // {} | keys | .[]" "$CONFIG_FILE" 2>/dev/null)
    
    # Get global scripts
    local global_scripts=$(jq -r ".global_scripts // {} | keys | .[]" "$CONFIG_FILE" 2>/dev/null)
    
    # Combine and deduplicate (project scripts override global)
    { echo "$project_scripts"; echo "$global_scripts"; } | sort -u | grep -v '^$'
}

# Check if script is global
is_global_script() {
    local script_name="$1"
    local exists=$(jq -r ".global_scripts[\"$script_name\"] // \"null\"" "$CONFIG_FILE")
    [[ "$exists" != "null" ]]
}

# Get script path (project or global)
get_script_path() {
    local project="$1"
    local script_name="$2"
    
    # Check project first
    local project_script=$(jq -r ".projects[\"$project\"].scripts[\"$script_name\"] // \"null\"" "$CONFIG_FILE")
    if [[ "$project_script" != "null" ]]; then
        echo ".projects[\"$project\"].scripts[\"$script_name\"]"
        return
    fi
    
    # Check global
    local global_script=$(jq -r ".global_scripts[\"$script_name\"] // \"null\"" "$CONFIG_FILE")
    if [[ "$global_script" != "null" ]]; then
        echo ".global_scripts[\"$script_name\"]"
        return
    fi
    
    echo ""
}

# Show available scripts
show_scripts() {
    local project="$1"
    
    echo -e "${YELLOW}Available scripts for ${BLUE}$project${NC}:"
    echo ""
    
    local scripts=$(list_scripts "$project")
    if [[ -z "$scripts" ]]; then
        echo -e "  ${DIM}No scripts defined${NC}"
        return
    fi
    
    echo "$scripts" | while IFS= read -r script_name; do
        [[ -z "$script_name" ]] && continue
        
        # Get script path (project or global)
        local script_path=$(get_script_path "$project" "$script_name")
        local is_global=""
        [[ "$script_path" == .global_scripts* ]] && is_global="🌐"
        
        # Check script type (array or object)
        local script_type=$(jq -r "$script_path | type" "$CONFIG_FILE")
        local steps
        local flags=""
        
        if [[ "$script_type" == "object" ]]; then
            steps=$(jq -r "${script_path}.steps | length" "$CONFIG_FILE")
            local notify=$(jq -r "${script_path}.notify // false" "$CONFIG_FILE")
            local has_failure=$(jq -r "${script_path}.on_failure // null" "$CONFIG_FILE")
            local has_loop=$(jq -r "${script_path}.loop.enabled // false" "$CONFIG_FILE")
            [[ "$notify" == "true" ]] && flags+="🔔"
            [[ "$has_failure" != "null" ]] && flags+="🔄"
            [[ "$has_loop" == "true" ]] && flags+="🔁"
        else
            steps=$(jq -r "$script_path | length" "$CONFIG_FILE")
        fi
        
        printf "  ${GREEN}%-16s${NC} ${DIM}(%s steps)${NC} %s%s\n" "$script_name" "$steps" "$is_global" "$flags"
    done
    
    echo ""
    echo -e "${DIM}Flags: 🌐 global  🔔 notifications  🔄 failure handler  🔁 loop/retry${NC}"
}

# Setup logging
setup_logging() {
    local project="$1"
    local script_name="$2"
    
    local log_dir=$(jq -r '.settings.log_dir // "~/.dev/logs"' "$CONFIG_FILE")
    log_dir="${log_dir/#\~/$HOME}"
    
    mkdir -p "$log_dir"
    
    local timestamp=$(date +%Y%m%d-%H%M%S)
    local log_file="$log_dir/${project}-${script_name}-${timestamp}.log"
    
    echo "$log_file"
}

# Run a script
run_script() {
    local project="$1"
    local project_root="$2"
    local script_name="$3"
    
    # Get script path (project or global)
    local script_base_path=$(get_script_path "$project" "$script_name")
    
    if [[ -z "$script_base_path" ]]; then
        echo -e "${RED}Error: Script '$script_name' not found${NC}"
        echo ""
        show_scripts "$project"
        return 1
    fi
    
    # Setup logging
    export LOG_FILE=$(setup_logging "$project" "$script_name")
    echo -e "${DIM}Log file: $LOG_FILE${NC}"
    
    # Check if script is array (simple) or object (with options)
    local script_type=$(jq -r "$script_base_path | type" "$CONFIG_FILE")
    local steps_path="$script_base_path"
    local should_notify="false"
    local on_failure_script=""
    local on_failure_shell=""
    local on_success_script=""
    local on_success_shell=""
    local loop_enabled="false"
    local loop_max_retries=3
    local loop_retry_delay=10
    
    if [[ "$script_type" == "object" ]]; then
        # Object format with options
        steps_path="${script_base_path}.steps"
        should_notify=$(jq -r "${script_base_path}.notify // false" "$CONFIG_FILE")
        on_failure_script=$(jq -r "${script_base_path}.on_failure.script // \"\"" "$CONFIG_FILE")
        on_failure_shell=$(jq -r "${script_base_path}.on_failure.shell // \"\"" "$CONFIG_FILE")
        on_success_script=$(jq -r "${script_base_path}.on_success.script // \"\"" "$CONFIG_FILE")
        on_success_shell=$(jq -r "${script_base_path}.on_success.shell // \"\"" "$CONFIG_FILE")
        loop_enabled=$(jq -r "${script_base_path}.loop.enabled // false" "$CONFIG_FILE")
        loop_max_retries=$(jq -r "${script_base_path}.loop.max_retries // 3" "$CONFIG_FILE")
        loop_retry_delay=$(jq -r "${script_base_path}.loop.retry_delay // 10" "$CONFIG_FILE")
    fi
    
    # Run with loop if enabled
    if [[ "$loop_enabled" == "true" ]]; then
        run_script_with_loop "$project" "$project_root" "$script_name" "$script_base_path" "$steps_path" \
            "$should_notify" "$on_failure_script" "$on_failure_shell" "$on_success_script" "$on_success_shell" \
            "$loop_max_retries" "$loop_retry_delay"
        return $?
    fi
    
    local steps=$(jq -r "$steps_path | length" "$CONFIG_FILE")
    
    echo -e "${BLUE}Running script:${NC} ${GREEN}$script_name${NC} ${DIM}($steps steps)${NC}"
    echo ""
    
    # Track context and failure info for on_failure handlers
    export PROJECT_NAME="$project"
    export PROJECT_ROOT="$project_root"
    export SCRIPT_NAME="$script_name"
    export FAILED_STEP=""
    export FAILED_ERROR=""
    export FAILED_STEP_NUM=""
    
    for ((i=0; i<steps; i++)); do
        local step_num=$((i + 1))
        
        # Check if step is a string (simple command) or object (with context)
        local step_type=$(jq -r "$steps_path[$i] | type" "$CONFIG_FILE")
        
        if [[ "$step_type" == "string" ]]; then
            # Simple command - run from root
            local step_cmd=$(jq -r "$steps_path[$i]" "$CONFIG_FILE")
            local cmd_to_run=$(get_command "$project" "/" "$step_cmd")
            
            if [[ -z "$cmd_to_run" ]]; then
                echo -e "${RED}[$step_num/$steps] Error: Unknown command '$step_cmd'${NC}"
                export FAILED_STEP="$step_cmd"
                export FAILED_STEP_NUM="$step_num"
                export FAILED_ERROR="Unknown command"
                handle_failure "$project" "$project_root" "$script_name" "$should_notify" "$on_failure_script" "$on_failure_shell"
                return 1
            fi
            
            echo -e "${CYAN}[$step_num/$steps]${NC} ${GREEN}$step_cmd${NC} ${DIM}→ $cmd_to_run${NC}"
            echo "[$step_num/$steps] $step_cmd → $cmd_to_run" >> "$LOG_FILE"
            cd "$project_root"
            if ! eval "$cmd_to_run" 2>&1 | tee -a "$LOG_FILE"; then
                echo -e "${RED}[$step_num/$steps] Failed${NC}"
                echo "[$step_num/$steps] FAILED" >> "$LOG_FILE"
                export FAILED_STEP="$step_cmd"
                export FAILED_STEP_NUM="$step_num"
                export FAILED_ERROR=$(tail -50 "$LOG_FILE")
                handle_failure "$project" "$project_root" "$script_name" "$should_notify" "$on_failure_script" "$on_failure_shell"
                return 1
            fi
            echo ""
        else
            # Object - check for shell command or context command
            local shell_cmd=$(jq -r "$steps_path[$i].shell // \"\"" "$CONFIG_FILE")
            
            if [[ -n "$shell_cmd" ]]; then
                # Direct shell command
                echo -e "${CYAN}[$step_num/$steps]${NC} ${GREEN}shell${NC} ${DIM}→ $shell_cmd${NC}"
                echo "[$step_num/$steps] shell → $shell_cmd" >> "$LOG_FILE"
                cd "$project_root"
                if ! eval "$shell_cmd" 2>&1 | tee -a "$LOG_FILE"; then
                    echo -e "${RED}[$step_num/$steps] Failed${NC}"
                    echo "[$step_num/$steps] FAILED" >> "$LOG_FILE"
                    export FAILED_STEP="shell: $shell_cmd"
                    export FAILED_STEP_NUM="$step_num"
                    export FAILED_ERROR=$(tail -50 "$LOG_FILE")
                    handle_failure "$project" "$project_root" "$script_name" "$should_notify" "$on_failure_script" "$on_failure_shell"
                    return 1
                fi
                echo ""
                continue
            fi
            
            # Object with context
            local context=$(jq -r "$steps_path[$i].context // \"/\"" "$CONFIG_FILE")
            local run_cmd=$(jq -r "$steps_path[$i].run" "$CONFIG_FILE")
            
            local cmd_to_run=$(get_command "$project" "$context" "$run_cmd")
            if [[ -z "$cmd_to_run" ]]; then
                # Try glob pattern matching for context
                local matched_context=$(find_context "$project" "$context")
                cmd_to_run=$(get_command "$project" "$matched_context" "$run_cmd")
            fi
            
            if [[ -z "$cmd_to_run" ]]; then
                echo -e "${RED}[$step_num/$steps] Error: Unknown command '$run_cmd' for context '$context'${NC}"
                export FAILED_STEP="$run_cmd (context: $context)"
                export FAILED_STEP_NUM="$step_num"
                export FAILED_ERROR="Unknown command"
                handle_failure "$project" "$project_root" "$script_name" "$should_notify" "$on_failure_script" "$on_failure_shell"
                return 1
            fi
            
            local target_dir="$project_root/$context"
            echo -e "${CYAN}[$step_num/$steps]${NC} ${GREEN}$run_cmd${NC} ${DIM}in $context → $cmd_to_run${NC}"
            echo "[$step_num/$steps] $run_cmd in $context → $cmd_to_run" >> "$LOG_FILE"
            
            if [[ ! -d "$target_dir" ]]; then
                echo -e "${RED}[$step_num/$steps] Error: Directory '$target_dir' not found${NC}"
                echo "[$step_num/$steps] FAILED: Directory not found: $target_dir" >> "$LOG_FILE"
                export FAILED_STEP="$run_cmd (context: $context)"
                export FAILED_STEP_NUM="$step_num"
                export FAILED_ERROR="Directory not found: $target_dir"
                handle_failure "$project" "$project_root" "$script_name" "$should_notify" "$on_failure_script" "$on_failure_shell"
                return 1
            fi
            
            cd "$target_dir"
            if ! eval "$cmd_to_run" 2>&1 | tee -a "$LOG_FILE"; then
                echo -e "${RED}[$step_num/$steps] Failed${NC}"
                echo "[$step_num/$steps] FAILED" >> "$LOG_FILE"
                export FAILED_STEP="$run_cmd (context: $context)"
                export FAILED_STEP_NUM="$step_num"
                export FAILED_ERROR=$(tail -50 "$LOG_FILE")
                handle_failure "$project" "$project_root" "$script_name" "$should_notify" "$on_failure_script" "$on_failure_shell"
                return 1
            fi
            echo ""
        fi
    done
    
    echo -e "${GREEN}✅ Script '$script_name' completed successfully${NC}"
    echo "=== SCRIPT COMPLETED SUCCESSFULLY ===" >> "$LOG_FILE"
    
    # Send success notification
    if [[ "$should_notify" == "true" ]]; then
        send_notification "$script_name" "Completed successfully" "success"
    fi
    
    # Run on_success handler
    if [[ -n "$on_success_script" ]]; then
        echo ""
        echo -e "${GREEN}Running success handler script: $on_success_script${NC}"
        run_script "$project" "$project_root" "$on_success_script"
    elif [[ -n "$on_success_shell" ]]; then
        echo ""
        echo -e "${GREEN}Running success handler...${NC}"
        cd "$project_root"
        eval "$on_success_shell"
    fi
}

# Run a script with retry loop
run_script_with_loop() {
    local project="$1"
    local project_root="$2"
    local script_name="$3"
    local script_base_path="$4"
    local steps_path="$5"
    local should_notify="$6"
    local on_failure_script="$7"
    local on_failure_shell="$8"
    local on_success_script="$9"
    local on_success_shell="${10}"
    local max_retries="${11}"
    local retry_delay="${12}"
    
    local attempt=1
    
    while [[ $attempt -le $max_retries ]]; do
        echo -e "${BLUE}🔄 Attempt $attempt/$max_retries${NC}"
        echo ""
        
        # Setup new log file for this attempt
        export LOG_FILE=$(setup_logging "$project" "${script_name}-attempt${attempt}")
        echo -e "${DIM}Log file: $LOG_FILE${NC}"
        
        # Track context
        export PROJECT_NAME="$project"
        export PROJECT_ROOT="$project_root"
        export SCRIPT_NAME="$script_name"
        export FAILED_STEP=""
        export FAILED_ERROR=""
        export FAILED_STEP_NUM=""
        export ATTEMPT_NUMBER="$attempt"
        
        local steps=$(jq -r "$steps_path | length" "$CONFIG_FILE")
        local failed=false
        
        echo -e "${BLUE}Running script:${NC} ${GREEN}$script_name${NC} ${DIM}($steps steps)${NC}"
        echo ""
        
        for ((i=0; i<steps; i++)); do
            local step_num=$((i + 1))
            local step_type=$(jq -r "$steps_path[$i] | type" "$CONFIG_FILE")
            
            if [[ "$step_type" == "string" ]]; then
                local step_cmd=$(jq -r "$steps_path[$i]" "$CONFIG_FILE")
                local cmd_to_run=$(get_command "$project" "/" "$step_cmd")
                
                if [[ -z "$cmd_to_run" ]]; then
                    export FAILED_STEP="$step_cmd"
                    export FAILED_STEP_NUM="$step_num"
                    export FAILED_ERROR="Unknown command"
                    failed=true
                    break
                fi
                
                echo -e "${CYAN}[$step_num/$steps]${NC} ${GREEN}$step_cmd${NC} ${DIM}→ $cmd_to_run${NC}"
                echo "[$step_num/$steps] $step_cmd → $cmd_to_run" >> "$LOG_FILE"
                cd "$project_root"
                
                if ! eval "$cmd_to_run" 2>&1 | tee -a "$LOG_FILE"; then
                    echo -e "${RED}[$step_num/$steps] Failed${NC}"
                    echo "[$step_num/$steps] FAILED" >> "$LOG_FILE"
                    export FAILED_STEP="$step_cmd"
                    export FAILED_STEP_NUM="$step_num"
                    export FAILED_ERROR=$(tail -50 "$LOG_FILE")
                    failed=true
                    break
                fi
                echo ""
            else
                local shell_cmd=$(jq -r "$steps_path[$i].shell // \"\"" "$CONFIG_FILE")
                
                if [[ -n "$shell_cmd" ]]; then
                    echo -e "${CYAN}[$step_num/$steps]${NC} ${GREEN}shell${NC} ${DIM}→ $shell_cmd${NC}"
                    echo "[$step_num/$steps] shell → $shell_cmd" >> "$LOG_FILE"
                    cd "$project_root"
                    
                    if ! eval "$shell_cmd" 2>&1 | tee -a "$LOG_FILE"; then
                        echo -e "${RED}[$step_num/$steps] Failed${NC}"
                        echo "[$step_num/$steps] FAILED" >> "$LOG_FILE"
                        export FAILED_STEP="shell: $shell_cmd"
                        export FAILED_STEP_NUM="$step_num"
                        export FAILED_ERROR=$(tail -50 "$LOG_FILE")
                        failed=true
                        break
                    fi
                    echo ""
                fi
            fi
        done
        
        if [[ "$failed" == "false" ]]; then
            # Success!
            echo -e "${GREEN}✅ Script '$script_name' completed successfully on attempt $attempt${NC}"
            
            if [[ "$should_notify" == "true" ]]; then
                send_notification "$script_name" "Completed successfully on attempt $attempt" "success"
            fi
            
            # Run on_success handler
            if [[ -n "$on_success_script" ]]; then
                echo ""
                echo -e "${GREEN}Running success handler script: $on_success_script${NC}"
                run_script "$project" "$project_root" "$on_success_script"
            elif [[ -n "$on_success_shell" ]]; then
                echo ""
                echo -e "${GREEN}Running success handler...${NC}"
                cd "$project_root"
                eval "$on_success_shell"
            fi
            
            return 0
        fi
        
        # Failed - run failure handler
        echo ""
        echo -e "${YELLOW}Attempt $attempt failed at step: $FAILED_STEP${NC}"
        
        if [[ "$should_notify" == "true" ]]; then
            send_notification "$script_name" "Attempt $attempt failed: $FAILED_STEP" "failure"
        fi
        
        # Run on_failure handler (which might fix things)
        if [[ -n "$on_failure_script" ]]; then
            echo ""
            echo -e "${YELLOW}Running failure handler script: $on_failure_script${NC}"
            run_script "$project" "$project_root" "$on_failure_script"
        elif [[ -n "$on_failure_shell" ]]; then
            echo ""
            echo -e "${YELLOW}Running failure handler...${NC}"
            cd "$project_root"
            eval "$on_failure_shell"
        fi
        
        # Check if we should retry
        if [[ $attempt -lt $max_retries ]]; then
            echo ""
            echo -e "${BLUE}⏳ Waiting ${retry_delay}s before retry...${NC}"
            sleep "$retry_delay"
        fi
        
        ((attempt++))
    done
    
    # All retries exhausted
    echo ""
    echo -e "${RED}❌ Script '$script_name' failed after $max_retries attempts${NC}"
    
    if [[ "$should_notify" == "true" ]]; then
        send_notification "$script_name" "Failed after $max_retries attempts" "failure"
    fi
    
    return 1
}

# Handle script failure
handle_failure() {
    local project="$1"
    local project_root="$2"
    local script_name="$3"
    local should_notify="$4"
    local on_failure_script="$5"
    local on_failure_shell="$6"
    
    # Send failure notification
    if [[ "$should_notify" == "true" ]]; then
        send_notification "$script_name" "Failed at step $FAILED_STEP_NUM: $FAILED_STEP" "failure"
    fi
    
    # Run on_failure handler
    if [[ -n "$on_failure_script" ]]; then
        echo ""
        echo -e "${YELLOW}Running failure handler script: $on_failure_script${NC}"
        run_script "$project" "$project_root" "$on_failure_script"
    elif [[ -n "$on_failure_shell" ]]; then
        echo ""
        echo -e "${YELLOW}Running failure handler...${NC}"
        cd "$project_root"
        eval "$on_failure_shell"
    fi
}

# ============================================================================
# Documentation Functions (LLM-friendly output)
# ============================================================================

# Generate LLM-friendly markdown documentation
show_docs() {
    local project="$1"
    local context="$2"
    local project_root="$3"
    
    echo "# dev CLI - $project"
    echo ""
    echo "Context-aware development commands for this repository."
    echo ""
    echo "## Current Context"
    echo ""
    echo "- **Project:** $project"
    echo "- **Root:** $project_root"
    echo "- **Context:** $context"
    echo "- **PWD:** $PWD"
    echo ""
    
    # Commands section
    echo "## Available Commands"
    echo ""
    echo "Run these with \`dev <command>\`:"
    echo ""
    
    # Group commands by category
    local commands=$(list_commands "$project" "$context")
    
    # Build category
    echo "### Build & Install"
    echo ""
    for cmd in build build:all codegen rebuild install reset; do
        local full_cmd=$(get_command "$project" "$context" "$cmd")
        if [[ -n "$full_cmd" ]]; then
            echo "- \`dev $cmd\` - \`$full_cmd\`"
        fi
    done
    echo ""
    
    # Quality category
    echo "### Code Quality"
    echo ""
    for cmd in lint format typecheck test; do
        local full_cmd=$(get_command "$project" "$context" "$cmd")
        if [[ -n "$full_cmd" ]]; then
            echo "- \`dev $cmd\` - \`$full_cmd\`"
        fi
    done
    echo ""
    
    # Clean category
    echo "### Clean Commands"
    echo ""
    for cmd in clean clean:dist clean:turbo clean:generated clean:node clean:all; do
        local full_cmd=$(get_command "$project" "$context" "$cmd")
        if [[ -n "$full_cmd" ]]; then
            local desc=""
            case "$cmd" in
                clean|clean:dist) desc="(dist/, .next/)" ;;
                clean:turbo) desc="(.turbo/)" ;;
                clean:generated) desc="(*.generated.ts)" ;;
                clean:node) desc="(node_modules + reinstall)" ;;
                clean:all) desc="(everything)" ;;
            esac
            echo "- \`dev $cmd\` $desc"
        fi
    done
    echo ""
    
    # Dev server category
    echo "### Dev Server"
    echo ""
    for cmd in start; do
        local full_cmd=$(get_command "$project" "$context" "$cmd")
        if [[ -n "$full_cmd" ]]; then
            echo "- \`dev $cmd\` - \`$full_cmd\`"
        fi
    done
    echo ""
    
    # Scripts section
    if [[ "$project" != default:* ]]; then
        local scripts=$(list_scripts "$project")
        if [[ -n "$scripts" ]]; then
            echo "## Multi-Step Scripts"
            echo ""
            echo "Run these with \`dev :run <script>\`:"
            echo ""
            
            echo "$scripts" | while IFS= read -r script_name; do
                [[ -z "$script_name" ]] && continue
                
                local script_path=$(get_script_path "$project" "$script_name")
                local script_type=$(jq -r "$script_path | type" "$CONFIG_FILE")
                local description=""
                
                if [[ "$script_type" == "object" ]]; then
                    description=$(jq -r "${script_path}.description // \"\"" "$CONFIG_FILE")
                fi
                
                if [[ -n "$description" ]]; then
                    echo "- \`dev :run $script_name\` - $description"
                else
                    echo "- \`dev :run $script_name\`"
                fi
            done
            echo ""
        fi
    fi
    
    # Usage tips for LLMs
    echo "## Usage Tips"
    echo ""
    echo "1. **Quick rebuild after branch switch:** \`dev rebuild\` (runs codegen + build)"
    echo "2. **Full reset:** \`dev :run fullreset\` (clean all + install + codegen + build)"
    echo "3. **Start dev server:** \`dev start\` (context-aware, runs in correct app)"
    echo "4. **Pre-PR checks:** \`dev :run pr:check\` (format + lint + typecheck + build + test)"
    echo "5. **Clean specific artifacts:** \`dev clean:turbo\` or \`dev clean:generated\`"
    echo ""
    echo "## Meta Commands"
    echo ""
    echo "- \`dev :list\` - List available commands"
    echo "- \`dev :scripts\` - List available scripts"
    echo "- \`dev :info\` - Show project detection info"
    echo "- \`dev :docs\` - Show this documentation"
    echo "- \`dev :root <cmd>\` - Run command from project root"
}

# ============================================================================
# Main
# ============================================================================

main() {
    local cmd="$1"
    shift 2>/dev/null || true
    local flags="$*"
    
    # Handle special commands
    case "$cmd" in
        -h|--help|help)
            show_help
            exit 0
            ;;
        :config)
            ${EDITOR:-nvim} "$CONFIG_FILE"
            exit 0
            ;;
    esac
    
    # Detect project
    local project=$(detect_project)
    if [[ -z "$project" ]]; then
        echo -e "${RED}Error: Could not detect project type${NC}"
        echo -e "${DIM}Run from a project directory or add detection rules to config${NC}"
        exit 1
    fi
    
    # Find project root
    local project_root="$PWD"
    if [[ "$project" != default:* ]]; then
        project_root=$(find_project_root "$project" 2>/dev/null || echo "$PWD")
    fi
    
    # Determine context
    local rel_path=$(get_relative_path "$project_root")
    local context=$(find_context "$project" "$rel_path")
    
    # Handle special commands that need project info
    case "$cmd" in
        ""|:list)
            show_commands "$project" "$context"
            exit 0
            ;;
        :scripts)
            show_scripts "$project"
            exit 0
            ;;
        :docs)
            show_docs "$project" "$context" "$project_root"
            exit 0
            ;;
        :run)
            local script_name="$1"
            if [[ -z "$script_name" ]]; then
                echo -e "${RED}Error: Script name required${NC}"
                echo "Usage: dev :run <script_name>"
                echo ""
                show_scripts "$project"
                exit 1
            fi
            run_script "$project" "$project_root" "$script_name"
            exit $?
            ;;
        :info)
            show_info "$project" "$context" "$project_root"
            exit 0
            ;;
        :root)
            # Run command from project root
            cd "$project_root"
            context="/"
            cmd="$1"
            shift 2>/dev/null || true
            flags="$*"
            ;;
    esac
    
    # Build full command key (e.g., "clean -t")
    local cmd_key="$cmd"
    [[ -n "$flags" ]] && cmd_key="$cmd $flags"
    
    # Try full command with flags first, then just command
    local full_cmd=$(get_command "$project" "$context" "$cmd_key")
    if [[ -z "$full_cmd" ]]; then
        full_cmd=$(get_command "$project" "$context" "$cmd")
    fi
    
    if [[ -z "$full_cmd" ]]; then
        echo -e "${RED}Error: Unknown command '$cmd' for project '$project' (context: $context)${NC}"
        echo ""
        show_commands "$project" "$context"
        exit 1
    fi
    
    # Execute from project root for consistency
    if [[ "$project" != default:* ]]; then
        cd "$project_root"
    fi
    
    echo -e "${BLUE}[$project]${NC} ${DIM}$context${NC}"
    echo -e "${GREEN}→${NC} $full_cmd"
    echo ""
    
    # Execute
    eval "$full_cmd"
}

main "$@"
