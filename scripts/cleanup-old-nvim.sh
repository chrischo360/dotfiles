#!/bin/bash

# cleanup-old-nvim.sh
# Kills nvim instances and their LSP servers older than specified hours or idle
# Usage: cleanup-old-nvim.sh [hours] [--dry-run] [--idle-only]

# Default: kill processes older than 48 hours (2 days)
MAX_AGE_HOURS=48
DRY_RUN=false
IDLE_ONLY=false

# Parse arguments
for arg in "$@"; do
    if [[ "$arg" == "--dry-run" ]]; then
        DRY_RUN=true
    elif [[ "$arg" == "--idle-only" ]]; then
        IDLE_ONLY=true
    elif [[ "$arg" =~ ^[0-9]+$ ]]; then
        MAX_AGE_HOURS="$arg"
    fi
done

if [[ "$DRY_RUN" == true ]]; then
    echo "🔍 DRY RUN MODE - No processes will be killed"
    echo ""
fi

if [[ "$IDLE_ONLY" == true ]]; then
    echo "💤 IDLE MODE - Only killing processes with very low CPU usage (likely unused)"
    echo ""
fi

# Convert hours to seconds for age comparison
MAX_AGE_SECONDS=$((MAX_AGE_HOURS * 3600))

# Get current time in seconds since epoch
CURRENT_TIME=$(date +%s)

echo "🧹 Cleaning up nvim instances older than ${MAX_AGE_HOURS} hours..."
echo ""

# Track totals
TOTAL_KILLED=0
TOTAL_MEMORY_FREED=0

# Find all nvim --embed processes
while IFS= read -r line; do
    # Parse ps output: PID START_TIME CPU_TIME RSS COMMAND
    PID=$(echo "$line" | awk '{print $1}')
    START_DATE=$(echo "$line" | awk '{print $2, $3, $4, $5, $6}')
    CPU_TIME=$(echo "$line" | awk '{print $7}')
    RSS=$(echo "$line" | awk '{print $8}')

    # Convert start time to seconds since epoch
    START_TIME=$(date -j -f "%a %b %d %H:%M:%S %Y" "$START_DATE" +%s 2>/dev/null)

    if [[ -z "$START_TIME" ]]; then
        continue
    fi

    # Calculate process age in seconds
    AGE_SECONDS=$((CURRENT_TIME - START_TIME))
    AGE_HOURS=$((AGE_SECONDS / 3600))
    AGE_DAYS=$((AGE_HOURS / 24))

    # Convert CPU time (MM:SS.MS) to seconds
    CPU_MINUTES=$(echo "$CPU_TIME" | cut -d: -f1)
    CPU_SECONDS=$(echo "$CPU_TIME" | cut -d: -f2 | cut -d. -f1)
    TOTAL_CPU_SECONDS=$((CPU_MINUTES * 60 + CPU_SECONDS))

    # Determine if process is idle (very low CPU usage for its age)
    # If running for 48+ hours but less than 2 minutes of CPU time = idle
    IS_IDLE=false
    if [[ $AGE_HOURS -ge 48 ]] && [[ $TOTAL_CPU_SECONDS -lt 120 ]]; then
        IS_IDLE=true
    fi

    # Decide whether to kill based on mode
    SHOULD_KILL=false
    REASON=""

    if [[ "$IDLE_ONLY" == true ]]; then
        # Only kill if idle
        if [[ "$IS_IDLE" == true ]]; then
            SHOULD_KILL=true
            REASON="idle for ${AGE_DAYS}d (${TOTAL_CPU_SECONDS}s CPU time)"
        fi
    else
        # Kill if older than threshold
        if [[ $AGE_SECONDS -gt $MAX_AGE_SECONDS ]]; then
            SHOULD_KILL=true
            REASON="age: ${AGE_HOURS}h"
            if [[ "$IS_IDLE" == true ]]; then
                REASON="${REASON} (idle)"
            fi
        fi
    fi

    # Check if we should kill this process
    if [[ "$SHOULD_KILL" == true ]]; then
        # Convert RSS from KB to MB
        MEMORY_MB=$((RSS / 1024))

        echo "📍 Found nvim instance to kill:"
        echo "   PID: $PID"
        echo "   Reason: $REASON"
        echo "   Age: ${AGE_DAYS}d ${AGE_HOURS}h"
        echo "   CPU Time: ${CPU_TIME}"
        echo "   Memory: ${MEMORY_MB} MB"
        echo "   Started: $START_DATE"

        # Find child processes (LSP servers)
        CHILD_PIDS=$(pgrep -P "$PID" 2>/dev/null)

        if [[ -n "$CHILD_PIDS" ]]; then
            echo "   Child processes (LSP servers):"
            for CHILD_PID in $CHILD_PIDS; do
                CHILD_INFO=$(ps -p "$CHILD_PID" -o pid=,rss=,command= 2>/dev/null)
                if [[ -n "$CHILD_INFO" ]]; then
                    CHILD_RSS=$(echo "$CHILD_INFO" | awk '{print $2}')
                    CHILD_CMD=$(echo "$CHILD_INFO" | awk '{$1=$2=""; print $0}' | sed 's/^ *//')
                    CHILD_MEMORY_MB=$((CHILD_RSS / 1024))
                    echo "      - PID $CHILD_PID: ${CHILD_MEMORY_MB} MB - $CHILD_CMD"
                fi
            done
        fi

        if [[ "$DRY_RUN" == false ]]; then
            # Kill child processes first
            if [[ -n "$CHILD_PIDS" ]]; then
                for CHILD_PID in $CHILD_PIDS; do
                    kill "$CHILD_PID" 2>/dev/null && echo "   ✅ Killed child PID $CHILD_PID"
                done
            fi

            # Kill parent nvim process
            kill "$PID" 2>/dev/null && echo "   ✅ Killed nvim PID $PID"

            # Wait a moment, then force kill if still alive
            sleep 0.5
            if ps -p "$PID" > /dev/null 2>&1; then
                kill -9 "$PID" 2>/dev/null && echo "   ⚠️  Force killed nvim PID $PID"
            fi

            TOTAL_KILLED=$((TOTAL_KILLED + 1))
            TOTAL_MEMORY_FREED=$((TOTAL_MEMORY_FREED + MEMORY_MB))
        else
            echo "   [DRY RUN] Would kill PID $PID and its children"
        fi

        echo ""
    fi
done < <(ps -eo pid,lstart,time,rss,command | grep "nvim --embed" | grep -v grep)

# Also check for orphaned LSP servers (node processes that lost their parent)
echo "🔍 Checking for orphaned LSP servers..."
echo ""

while IFS= read -r line; do
    PID=$(echo "$line" | awk '{print $1}')
    PARENT_PID=$(echo "$line" | awk '{print $2}')
    START_DATE=$(echo "$line" | awk '{print $3, $4, $5, $6, $7}')
    RSS=$(echo "$line" | awk '{print $8}')
    COMMAND=$(echo "$line" | awk '{for(i=9;i<=NF;i++) printf $i" "; print ""}')

    # Check if it's an LSP server
    if [[ "$COMMAND" =~ (intelephense|typescript-language-server|pyright|rust-analyzer|lua-language-server) ]]; then
        # Check if parent process still exists
        if ! ps -p "$PARENT_PID" > /dev/null 2>&1; then
            MEMORY_MB=$((RSS / 1024))

            echo "👻 Found orphaned LSP server:"
            echo "   PID: $PID (parent $PARENT_PID is dead)"
            echo "   Memory: ${MEMORY_MB} MB"
            echo "   Command: $COMMAND"

            if [[ "$DRY_RUN" == false ]]; then
                kill "$PID" 2>/dev/null && echo "   ✅ Killed orphaned PID $PID"
                sleep 0.2
                if ps -p "$PID" > /dev/null 2>&1; then
                    kill -9 "$PID" 2>/dev/null && echo "   ⚠️  Force killed PID $PID"
                fi
                TOTAL_MEMORY_FREED=$((TOTAL_MEMORY_FREED + MEMORY_MB))
            else
                echo "   [DRY RUN] Would kill PID $PID"
            fi
            echo ""
        fi
    fi
done < <(ps -eo pid,ppid,lstart,rss,command | grep node | grep -v grep)

# Summary
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [[ "$DRY_RUN" == false ]]; then
    echo "✅ Cleanup complete!"
    echo "   Processes killed: $TOTAL_KILLED"
    echo "   Memory freed: ~${TOTAL_MEMORY_FREED} MB"
else
    echo "🔍 Dry run complete - no processes were killed"
fi
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
