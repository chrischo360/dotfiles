#!/bin/bash

# nvim-process-report.sh
# Shows all nvim, node, and LSP processes with memory and working directory
# Usage: nvim-process-report.sh [--summary]

SUMMARY_ONLY=false

if [[ "$1" == "--summary" ]]; then
    SUMMARY_ONLY=true
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 NVIM & LSP PROCESS REPORT"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
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
done < <(ps -eo pid,rss,lstart,time,command | grep "nvim --embed" | grep -v grep)

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
    COMMAND=$(echo "$line" | awk '{for(i=4;i<=NF;i++) printf $i" "; print ""}')

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
done < <(ps -eo pid,ppid,rss,command | grep -E "intelephense|typescript-language-server|pyright|rust-analyzer|lua-language-server" | grep -v grep)

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
    COMMAND=$(echo "$line" | awk '{for(i=3;i<=NF;i++) printf $i" "; print ""}')

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
done < <(ps -eo pid,rss,command | grep node | grep -v grep)

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
