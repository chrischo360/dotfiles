#!/bin/bash

# nvim-memory-notify.sh
# Runs nvim memory report and sends macOS notification
# Designed to run automatically via LaunchAgent every 48 hours

LOG_FILE="$HOME/.local/log/nvim-memory-report.log"
REPORT_SCRIPT="$HOME/dotfiles/scripts/nvim-process-report.sh"

# Ensure log directory exists
mkdir -p "$(dirname "$LOG_FILE")"

# Generate timestamp
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# Run the report and capture output
REPORT_OUTPUT=$("$REPORT_SCRIPT" 2>&1)

# Extract process IDs for kill commands
NVIM_PIDS=$(ps -eo pid,command | grep "nvim --embed" | grep -v grep | awk '{print $1}' | tr '\n' ' ')
LSP_PIDS=$(ps -eo pid,command | grep -E "intelephense|typescript-language-server|pyright|rust-analyzer|lua-language-server" | grep -v grep | awk '{print $1}' | tr '\n' ' ')
NODE_PIDS=$(ps -eo pid,command | grep node | grep -v grep | grep -v -E "intelephense|typescript-language-server|pyright|rust-analyzer|lua-language-server" | awk '{print $1}' | tr '\n' ' ')

# Write to log file with timestamp
{
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Report generated: $TIMESTAMP"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "$REPORT_OUTPUT"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🔪 QUICK KILL COMMANDS (copy-paste to kill processes)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    if [[ -n "$NVIM_PIDS" ]]; then
        echo "Kill all nvim instances (${NVIM_COUNT:-0} processes):"
        echo "  kill $NVIM_PIDS"
        echo ""
    else
        echo "No nvim instances to kill"
        echo ""
    fi

    if [[ -n "$LSP_PIDS" ]]; then
        echo "Kill all LSP servers (${LSP_COUNT:-0} processes):"
        echo "  kill $LSP_PIDS"
        echo ""
    else
        echo "No LSP servers to kill"
        echo ""
    fi

    if [[ -n "$NODE_PIDS" ]]; then
        echo "Kill all other node processes (${NODE_COUNT:-0} processes):"
        echo "  kill $NODE_PIDS"
        echo ""
    else
        echo "No other node processes to kill"
        echo ""
    fi

    echo "Kill everything (nvim + LSP + node):"
    if [[ -n "$NVIM_PIDS" ]] || [[ -n "$LSP_PIDS" ]] || [[ -n "$NODE_PIDS" ]]; then
        echo "  kill $NVIM_PIDS $LSP_PIDS $NODE_PIDS"
    else
        echo "  (nothing to kill)"
    fi
    echo ""

    echo "Or use the cleanup script for old processes only (2+ days):"
    echo "  ~/dotfiles/scripts/cleanup-old-nvim.sh --dry-run  # see what would be killed"
    echo "  ~/dotfiles/scripts/cleanup-old-nvim.sh            # actually kill old processes"
    echo ""

    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo ""
} >> "$LOG_FILE"

# Extract summary data from report
# Look for lines like:
#   Nvim instances:      5 processes → 268 MB
#   LSP servers:         2 processes → 1148 MB
#   GRAND TOTAL:         1431 MB (~1.39 GB)

NVIM_COUNT=$(echo "$REPORT_OUTPUT" | grep "Nvim instances:" | awk '{print $3}')
NVIM_MEMORY=$(echo "$REPORT_OUTPUT" | grep "Nvim instances:" | awk '{print $6}')

LSP_COUNT=$(echo "$REPORT_OUTPUT" | grep "LSP servers:" | awk '{print $3}')
LSP_MEMORY=$(echo "$REPORT_OUTPUT" | grep "LSP servers:" | awk '{print $6}')

NODE_COUNT=$(echo "$REPORT_OUTPUT" | grep "Other node:" | awk '{print $3}')
NODE_MEMORY=$(echo "$REPORT_OUTPUT" | grep "Other node:" | awk '{print $6}')

TOTAL_MB=$(echo "$REPORT_OUTPUT" | grep "GRAND TOTAL:" | awk '{print $3}')
TOTAL_GB=$(echo "$REPORT_OUTPUT" | grep "GRAND TOTAL:" | grep -o '~[0-9.]*' | tr -d '~')

# Fallback if parsing fails
if [[ -z "$TOTAL_MB" ]]; then
    TOTAL_MB="unknown"
    TOTAL_GB="unknown"
fi

# Build notification message
NOTIFICATION_TITLE="📊 Nvim Memory Report"
NOTIFICATION_MESSAGE="${NVIM_COUNT:-0} nvim (${NVIM_MEMORY:-0} MB) + ${LSP_COUNT:-0} LSP (${LSP_MEMORY:-0} MB) = ${TOTAL_GB:-?} GB total"
NOTIFICATION_SUBTITLE="Click to view detailed report"

# Determine alert level based on memory usage
SOUND="default"
if [[ -n "$TOTAL_MB" ]] && [[ "$TOTAL_MB" != "unknown" ]]; then
    if [[ $TOTAL_MB -gt 5000 ]]; then
        # Over 5 GB - critical
        NOTIFICATION_TITLE="🚨 Nvim Memory Alert - HIGH"
        SOUND="Basso"
    elif [[ $TOTAL_MB -gt 3000 ]]; then
        # Over 3 GB - warning
        NOTIFICATION_TITLE="⚠️  Nvim Memory Warning"
        SOUND="Funk"
    fi
fi

# Send macOS notification
if command -v terminal-notifier &> /dev/null; then
    terminal-notifier \
        -title "$NOTIFICATION_TITLE" \
        -subtitle "$NOTIFICATION_SUBTITLE" \
        -message "$NOTIFICATION_MESSAGE" \
        -sound "$SOUND" \
        -open "file://$LOG_FILE" \
        -group "nvim-memory-monitor"
else
    # Fallback to osascript if terminal-notifier not available
    osascript -e "display notification \"$NOTIFICATION_MESSAGE\" with title \"$NOTIFICATION_TITLE\" subtitle \"$NOTIFICATION_SUBTITLE\" sound name \"$SOUND\""
fi

# Also print to stdout for manual runs
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "$NOTIFICATION_TITLE"
echo "$NOTIFICATION_SUBTITLE"
echo "$NOTIFICATION_MESSAGE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Full report saved to: $LOG_FILE"
echo ""

# Show quick kill commands
echo "🔪 Quick Kill Commands:"
echo ""
if [[ -n "$NVIM_PIDS" ]]; then
    echo "  Kill all nvim (${NVIM_COUNT:-0}):  kill $NVIM_PIDS"
fi
if [[ -n "$LSP_PIDS" ]]; then
    echo "  Kill all LSP (${LSP_COUNT:-0}):   kill $LSP_PIDS"
fi
if [[ -n "$NODE_PIDS" ]]; then
    echo "  Kill all node (${NODE_COUNT:-0}):  kill $NODE_PIDS"
fi
echo ""
echo "  Or use cleanup script: ~/dotfiles/scripts/cleanup-old-nvim.sh"
echo ""

# Keep only last 30 days of logs (prevent log file from growing forever)
# Find the line number of the last report from 30 days ago
CUTOFF_DATE=$(date -v-30d '+%Y-%m-%d')
if [[ -f "$LOG_FILE" ]]; then
    # Keep file size manageable (keep last 10000 lines if file is huge)
    LINE_COUNT=$(wc -l < "$LOG_FILE")
    if [[ $LINE_COUNT -gt 10000 ]]; then
        tail -10000 "$LOG_FILE" > "${LOG_FILE}.tmp"
        mv "${LOG_FILE}.tmp" "$LOG_FILE"
    fi
fi

exit 0
