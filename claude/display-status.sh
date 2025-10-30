#!/bin/bash

# Claude Code Status Display Hook
# Displays token usage and GCP Vertex AI cost estimation
# Can be called from hooks or manually

# Source the token tracker for cost calculation functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/token-tracker.sh"

# Get current model from settings or use default
MODEL=${CLAUDE_MODEL:-"opus"}  # Default to opus since that's in your settings

# Get token usage from environment variables (if set by Claude Code)
TOKENS_USED=${CLAUDE_TOKENS_USED:-0}
TOKENS_TOTAL=${CLAUDE_TOKENS_TOTAL:-200000}
TOKENS_REMAINING=$((TOKENS_TOTAL - TOKENS_USED))

# Calculate percentage
if [ "$TOKENS_TOTAL" -gt 0 ]; then
    PERCENTAGE=$(echo "scale=1; ($TOKENS_USED * 100) / $TOKENS_TOTAL" | bc)
else
    PERCENTAGE=0
fi

# Estimate input/output token split (70/30 is a conservative estimate)
INPUT_TOKENS=$(echo "scale=0; $TOKENS_USED * 0.7 / 1" | bc)
OUTPUT_TOKENS=$(echo "scale=0; $TOKENS_USED * 0.3 / 1" | bc)

# Calculate cost
COST=$(calculate_cost "$INPUT_TOKENS" "$OUTPUT_TOKENS" "$MODEL")

# Display format
if [ -t 1 ]; then
    # Terminal with colors
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    RED='\033[0;31m'
    BLUE='\033[0;34m'
    CYAN='\033[0;36m'
    NC='\033[0m'

    # Color based on usage
    if (( $(echo "$PERCENTAGE < 50" | bc -l) )); then
        COLOR=$GREEN
    elif (( $(echo "$PERCENTAGE < 80" | bc -l) )); then
        COLOR=$YELLOW
    else
        COLOR=$RED
    fi

    echo -e "\n${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}📊 Token Usage:${NC} ${COLOR}${TOKENS_USED}${NC} / ${TOKENS_TOTAL} (${COLOR}${PERCENTAGE}%${NC})"
    echo -e "${BLUE}⏳ Remaining:${NC} ${TOKENS_REMAINING} tokens"
    echo -e "${BLUE}💰 Est. Cost:${NC} \$${COST} ${CYAN}(GCP Vertex AI - ${MODEL})${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
else
    # Plain text
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📊 Token Usage: ${TOKENS_USED} / ${TOKENS_TOTAL} (${PERCENTAGE}%)"
    echo "⏳ Remaining: ${TOKENS_REMAINING} tokens"
    echo "💰 Est. Cost: \$${COST} (GCP Vertex AI - ${MODEL})"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
fi
