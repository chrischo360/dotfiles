#!/bin/bash

# memory.sh
# Shows process memory usage with configurable presets
# Usage: memory.sh [OPTIONS]

# Default preset
PRESET="nvim"
SUMMARY_ONLY=false

# Help function
show_help() {
    echo "Usage: memory.sh [OPTIONS]"
    echo ""
    echo "OPTIONS:"
    echo "  --nvim          Monitor nvim, LSP, and node processes (default)"
    echo "  --chrome        Monitor Chrome/Chromium processes"
    echo "  --docker        Monitor Docker-related processes"
    echo "  --node          Monitor all Node.js processes"
    echo "  --all           Monitor all processes (top 20 by memory)"
    echo "  --summary       Show summary only, skip detailed listings"
    echo "  -h, --help      Show this help message"
    echo ""
    echo "Examples:"
    echo "  memory.sh                # Default: nvim/LSP/node"
    echo "  memory.sh --chrome       # Chrome memory usage"
    echo "  memory.sh --docker       # Docker memory usage"
    echo "  memory.sh --all          # All processes by memory"
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --nvim)
            PRESET="nvim"
            shift
            ;;
        --chrome|--chromium)
            PRESET="chrome"
            shift
            ;;
        --docker)
            PRESET="docker"
            shift
            ;;
        --node)
            PRESET="node"
            shift
            ;;
        --all)
            PRESET="all"
            shift
            ;;
        --summary)
            SUMMARY_ONLY=true
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Preset titles
case $PRESET in
    nvim)
        REPORT_TITLE="NVIM & LSP PROCESS REPORT"
        ;;
    chrome)
        REPORT_TITLE="CHROME/CHROMIUM PROCESS REPORT"
        ;;
    docker)
        REPORT_TITLE="DOCKER PROCESS REPORT"
        ;;
    node)
        REPORT_TITLE="NODE.JS PROCESS REPORT"
        ;;
    all)
        REPORT_TITLE="ALL PROCESSES (TOP 20 BY MEMORY)"
        ;;
esac

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 $REPORT_TITLE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# For non-nvim presets, use simplified reporting
if [[ "$PRESET" != "nvim" ]]; then
    # Determine process pattern
    case $PRESET in
        chrome)
            PATTERN="Google Chrome Helper|Chromium Helper|Google Chrome|Chromium"
            ;;
        docker)
            PATTERN="com.docker|docker|containerd"
            ;;
        node)
            PATTERN="node"
            ;;
        all)
            PATTERN="."
            ;;
    esac

    TOTAL_MEMORY=0
    PROC_COUNT=0

    echo "┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓"
    echo "┃ PROCESSES                                                  ┃"
    echo "┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛"
    echo ""

    # Get processes, sort by memory, limit to top 20 for --all
    if [[ "$PRESET" == "all" ]]; then
        PROCESS_LIST=$(ps -eo pid,rss,command | grep -v "PID" | sort -k2 -rn | head -20)
    else
        PROCESS_LIST=$(ps -eo pid,rss,command | grep -E "$PATTERN" | grep -v grep | sort -k2 -rn)
    fi

    while IFS= read -r line; do
        [[ -z "$line" ]] && continue

        PID=$(echo "$line" | awk '{print $1}')
        RSS=$(echo "$line" | awk '{print $2}')
        COMMAND=$(echo "$line" | awk '{for(i=3;i<=NF;i++) printf "%s ", $i; print ""}')

        # Get working directory
        CWD=$(lsof -p "$PID" 2>/dev/null | grep cwd | awk '{print $NF}')
        if [[ -z "$CWD" ]]; then
            CWD="<unknown>"
        fi

        # Convert RSS to MB
        MEMORY_MB=$((RSS / 1024))
        TOTAL_MEMORY=$((TOTAL_MEMORY + MEMORY_MB))
        PROC_COUNT=$((PROC_COUNT + 1))

        if [[ "$SUMMARY_ONLY" == false ]]; then
            # Truncate long commands
            COMMAND_SHORT=$(echo "$COMMAND" | cut -c1-70)
            if [[ ${#COMMAND} -gt 70 ]]; then
                COMMAND_SHORT="${COMMAND_SHORT}..."
            fi

            echo "  PID: $PID"
            echo "    Memory:    ${MEMORY_MB} MB"
            echo "    Command:   ${COMMAND_SHORT}"
            echo "    Directory: ${CWD}"
            echo ""
        fi
    done <<< "$PROCESS_LIST"

    echo "  Total: $PROC_COUNT processes using ${TOTAL_MEMORY} MB"
    echo ""

    # Grand Total (simplified for non-nvim presets)
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📈 TOTAL MEMORY USAGE"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    GRAND_TOTAL_GB=$(echo "scale=2; $TOTAL_MEMORY / 1024" | bc)
    echo "  GRAND TOTAL:         $TOTAL_MEMORY MB (~${GRAND_TOTAL_GB} GB)"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    # Show cleanup commands
    echo "💡 CLEANUP COMMANDS"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    case $PRESET in
        chrome)
            echo "  Kill Chrome processes:"
            echo "    pkill -f \"Google Chrome\""
            echo "    pkill -f Chromium"
            echo ""
            echo "  Kill specific process:"
            echo "    kill <PID>              # Graceful shutdown"
            echo "    kill -9 <PID>           # Force kill"
            ;;
        docker)
            echo "  Stop all containers:"
            echo "    docker stop \$(docker ps -q)"
            echo ""
            echo "  Kill Docker daemon:"
            echo "    pkill -f docker"
            echo "    pkill -f containerd"
            echo ""
            echo "  Restart Docker Desktop:"
            echo "    killall Docker && open -a Docker"
            ;;
        node)
            echo "  Kill all node processes (⚠️  careful!):"
            echo "    pkill node              # Kills ALL node processes"
            echo "    pkill -9 node           # Force kill all"
            echo ""
            echo "  Kill specific process:"
            echo "    kill <PID>              # Graceful shutdown"
            echo "    kill -9 <PID>           # Force kill"
            ;;
        all)
            echo "  Kill specific process:"
            echo "    kill <PID>              # Graceful shutdown"
            echo "    kill -9 <PID>           # Force kill"
            echo ""
            echo "  View process details:"
            echo "    ps -p <PID> -o pid,ppid,user,%cpu,%mem,command"
            ;;
    esac

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    exit 0
fi

# Continue with nvim-specific reporting (original code)
echo ""

# Totals
TOTAL_NVIM_MEMORY=0
TOTAL_LSP_MEMORY=0
TOTAL_NODE_MEMORY=0
NVIM_COUNT=0
LSP_COUNT=0
NODE_COUNT=0

# Section 1: Nvim Processes
echo "┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓"
echo "┃ 1. NVIM INSTANCES                                          ┃"
echo "┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛"
echo ""

while IFS= read -r line; do
    PID=$(echo "$line" | awk '{print $1}')
    RSS=$(echo "$line" | awk '{print $2}')
    LSTART=$(echo "$line" | awk '{print $3, $4, $5, $6, $7}')
    CPU_TIME=$(echo "$line" | awk '{print $8}')

    # Get working directory
    CWD=$(lsof -p "$PID" 2>/dev/null | grep cwd | awk '{print $NF}')
    if [[ -z "$CWD" ]]; then
        CWD="<unknown>"
    fi

    # Convert RSS to MB
    MEMORY_MB=$((RSS / 1024))
    TOTAL_NVIM_MEMORY=$((TOTAL_NVIM_MEMORY + MEMORY_MB))
    NVIM_COUNT=$((NVIM_COUNT + 1))

    if [[ "$SUMMARY_ONLY" == false ]]; then
        echo "  PID: $PID"
        echo "    Memory:    ${MEMORY_MB} MB"
        echo "    CPU Time:  ${CPU_TIME}"
        echo "    Started:   ${LSTART}"
        echo "    Directory: ${CWD}"

        # Find child LSP processes
        CHILD_PIDS=$(pgrep -P "$PID" 2>/dev/null)
        if [[ -n "$CHILD_PIDS" ]]; then
            echo "    LSP Servers:"
            for CHILD_PID in $CHILD_PIDS; do
                CHILD_INFO=$(ps -p "$CHILD_PID" -o pid=,rss=,command= 2>/dev/null)
                if [[ -n "$CHILD_INFO" ]]; then
                    CHILD_RSS=$(echo "$CHILD_INFO" | awk '{print $2}')
                    CHILD_CMD=$(echo "$CHILD_INFO" | awk '{$1=$2=""; print $0}' | sed 's/^ *//')
                    CHILD_MEMORY_MB=$((CHILD_RSS / 1024))

                    # Extract LSP server name
                    LSP_NAME="unknown"
                    if [[ "$CHILD_CMD" =~ intelephense ]]; then
                        LSP_NAME="Intelephense (PHP)"
                    elif [[ "$CHILD_CMD" =~ typescript-language-server ]]; then
                        LSP_NAME="TypeScript LS"
                    elif [[ "$CHILD_CMD" =~ pyright ]]; then
                        LSP_NAME="Pyright (Python)"
                    elif [[ "$CHILD_CMD" =~ rust-analyzer ]]; then
                        LSP_NAME="Rust Analyzer"
                    elif [[ "$CHILD_CMD" =~ lua-language-server ]]; then
                        LSP_NAME="Lua LS"
                    fi

                    echo "      • $LSP_NAME (PID $CHILD_PID): ${CHILD_MEMORY_MB} MB"
                fi
            done
        fi
        echo ""
    fi
done < <(ps -eo pid,rss,lstart,time,command | grep "nvim --embed" | grep -v grep | sort -k2 -rn)

echo "  Total: $NVIM_COUNT nvim instances using ${TOTAL_NVIM_MEMORY} MB"
echo ""

# Section 2: LSP Server Processes
echo "┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓"
echo "┃ 2. LSP SERVER PROCESSES                                    ┃"
echo "┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛"
echo ""

# Find all LSP servers
while IFS= read -r line; do
    PROC_PID=$(echo "$line" | awk '{print $1}')
    PARENT_PID=$(echo "$line" | awk '{print $2}')
    RSS=$(echo "$line" | awk '{print $3}')
    COMMAND=$(echo "$line" | awk '{for(i=4;i<=NF;i++) printf "%s ", $i; print ""}')

    # Get working directory
    CWD=$(lsof -p "$PROC_PID" 2>/dev/null | grep cwd | awk '{print $NF}')
    if [[ -z "$CWD" ]]; then
        CWD="<unknown>"
    fi

    # Determine LSP type
    LSP_TYPE="Unknown"
    if [[ "$COMMAND" =~ intelephense ]]; then
        LSP_TYPE="Intelephense (PHP)"
    elif [[ "$COMMAND" =~ typescript-language-server ]]; then
        LSP_TYPE="TypeScript LS"
    elif [[ "$COMMAND" =~ pyright ]]; then
        LSP_TYPE="Pyright (Python)"
    elif [[ "$COMMAND" =~ rust-analyzer ]]; then
        LSP_TYPE="Rust Analyzer"
    elif [[ "$COMMAND" =~ lua-language-server ]]; then
        LSP_TYPE="Lua LS"
    else
        continue  # Skip non-LSP node processes
    fi

    # Convert RSS to MB
    MEMORY_MB=$((RSS / 1024))
    TOTAL_LSP_MEMORY=$((TOTAL_LSP_MEMORY + MEMORY_MB))
    LSP_COUNT=$((LSP_COUNT + 1))

    # Check if parent still exists
    PARENT_STATUS="✅"
    if ! ps -p "$PARENT_PID" > /dev/null 2>&1; then
        PARENT_STATUS="👻 ORPHANED"
    fi

    if [[ "$SUMMARY_ONLY" == false ]]; then
        echo "  $LSP_TYPE"
        echo "    PID:       $PROC_PID (parent: $PARENT_PID $PARENT_STATUS)"
        echo "    Memory:    ${MEMORY_MB} MB"
        echo "    Directory: ${CWD}"
        echo ""
    fi
done < <(ps -eo pid,ppid,rss,command | grep -E "intelephense|typescript-language-server|pyright|rust-analyzer|lua-language-server" | grep -v grep | sort -k3 -rn)

echo "  Total: $LSP_COUNT LSP servers using ${TOTAL_LSP_MEMORY} MB"
echo ""

# Section 3: Other Node Processes
echo "┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓"
echo "┃ 3. OTHER NODE PROCESSES (non-LSP)                         ┃"
echo "┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛"
echo ""

while IFS= read -r line; do
    PID=$(echo "$line" | awk '{print $1}')
    RSS=$(echo "$line" | awk '{print $2}')
    COMMAND=$(echo "$line" | awk '{for(i=3;i<=NF;i++) printf "%s ", $i; print ""}')

    # Skip LSP servers (already counted)
    if [[ "$COMMAND" =~ (intelephense|typescript-language-server|pyright|rust-analyzer|lua-language-server) ]]; then
        continue
    fi

    # Get working directory
    CWD=$(lsof -p "$PID" 2>/dev/null | grep cwd | awk '{print $NF}')
    if [[ -z "$CWD" ]]; then
        CWD="<unknown>"
    fi

    # Convert RSS to MB
    MEMORY_MB=$((RSS / 1024))
    TOTAL_NODE_MEMORY=$((TOTAL_NODE_MEMORY + MEMORY_MB))
    NODE_COUNT=$((NODE_COUNT + 1))

    if [[ "$SUMMARY_ONLY" == false ]]; then
        # Truncate long commands
        COMMAND_SHORT=$(echo "$COMMAND" | cut -c1-60)
        if [[ ${#COMMAND} -gt 60 ]]; then
            COMMAND_SHORT="${COMMAND_SHORT}..."
        fi

        echo "  PID: $PID"
        echo "    Memory:    ${MEMORY_MB} MB"
        echo "    Command:   ${COMMAND_SHORT}"
        echo "    Directory: ${CWD}"
        echo ""
    fi
done < <(ps -eo pid,rss,command | grep node | grep -v grep | sort -k2 -rn)

echo "  Total: $NODE_COUNT node processes using ${TOTAL_NODE_MEMORY} MB"
echo ""

# Grand Total
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📈 TOTAL MEMORY USAGE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "  Nvim instances:      ${NVIM_COUNT} processes → ${TOTAL_NVIM_MEMORY} MB"
echo "  LSP servers:         ${LSP_COUNT} processes → ${TOTAL_LSP_MEMORY} MB"
echo "  Other node:          ${NODE_COUNT} processes → ${TOTAL_NODE_MEMORY} MB"
echo ""
GRAND_TOTAL=$((TOTAL_NVIM_MEMORY + TOTAL_LSP_MEMORY + TOTAL_NODE_MEMORY))
GRAND_TOTAL_GB=$(echo "scale=2; $GRAND_TOTAL / 1024" | bc)
echo "  GRAND TOTAL:         $GRAND_TOTAL MB (~${GRAND_TOTAL_GB} GB)"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "💡 CLEANUP COMMANDS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "  Kill specific process:"
echo "    kill <PID>              # Graceful shutdown"
echo "    kill -9 <PID>           # Force kill"
echo ""
echo "  Kill all nvim processes:"
echo "    pkill nvim              # Kill all nvim instances"
echo "    pkill -9 nvim           # Force kill all nvim"
echo ""
echo "  Kill orphaned LSP servers:"
echo "    pkill -f typescript-language-server"
echo "    pkill -f intelephense"
echo "    pkill -f pyright"
echo "    pkill -f rust-analyzer"
echo "    pkill -f lua-language-server"
echo ""
echo "  Kill all node processes (⚠️  careful!):"
echo "    pkill node              # Kills ALL node processes"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
