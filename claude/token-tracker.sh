#!/bin/bash

# Claude Code Token Usage and Cost Tracker for GCP Vertex AI
# This script calculates real-time token usage and estimated costs

# GCP Vertex AI pricing for Claude models (as of 2025)
# Prices are per 1M tokens
# Reference: https://cloud.google.com/vertex-ai/generative-ai/pricing

# Claude Sonnet 4.5 (current model based on settings)
SONNET_4_5_INPUT_PRICE=3.00    # $3.00 per 1M input tokens
SONNET_4_5_OUTPUT_PRICE=15.00  # $15.00 per 1M output tokens

# Claude Opus 4
OPUS_4_INPUT_PRICE=15.00       # $15.00 per 1M input tokens
OPUS_4_OUTPUT_PRICE=75.00      # $75.00 per 1M output tokens

# Claude Haiku 4
HAIKU_4_INPUT_PRICE=0.40       # $0.40 per 1M input tokens
HAIKU_4_OUTPUT_PRICE=2.00      # $2.00 per 1M output tokens

# Function to calculate cost
calculate_cost() {
    local input_tokens=$1
    local output_tokens=$2
    local model=${3:-"sonnet"}

    case "$model" in
        "opus")
            INPUT_PRICE=$OPUS_4_INPUT_PRICE
            OUTPUT_PRICE=$OPUS_4_OUTPUT_PRICE
            ;;
        "haiku")
            INPUT_PRICE=$HAIKU_4_INPUT_PRICE
            OUTPUT_PRICE=$HAIKU_4_OUTPUT_PRICE
            ;;
        "sonnet"|*)
            INPUT_PRICE=$SONNET_4_5_INPUT_PRICE
            OUTPUT_PRICE=$SONNET_4_5_OUTPUT_PRICE
            ;;
    esac

    # Calculate costs (divide by 1,000,000 to get cost per token, then multiply by token count)
    input_cost=$(echo "scale=6; $input_tokens * $INPUT_PRICE / 1000000" | bc)
    output_cost=$(echo "scale=6; $output_tokens * $OUTPUT_PRICE / 1000000" | bc)
    total_cost=$(echo "scale=6; $input_cost + $output_cost" | bc)

    # Format to 4 decimal places for display
    printf "%.4f" "$total_cost"
}

# Function to parse token usage from Claude Code session
# This reads from stdin or a log file
parse_tokens() {
    local log_file=${1:-}

    if [ -n "$log_file" ] && [ -f "$log_file" ]; then
        # Parse from log file
        grep -o "Token usage: [0-9]*/[0-9]*" "$log_file" | tail -1
    else
        # Read from environment or defaults
        echo "${CLAUDE_TOKENS_USED:-0}/${CLAUDE_TOKENS_TOTAL:-200000}"
    fi
}

# Function to display status line
display_status() {
    local tokens_info=$1
    local model=${2:-"sonnet"}

    # Parse tokens used and total
    tokens_used=$(echo "$tokens_info" | cut -d'/' -f1 | tr -d ' ')
    tokens_total=$(echo "$tokens_info" | cut -d'/' -f2 | tr -d ' ')
    tokens_remaining=$((tokens_total - tokens_used))

    # Calculate percentage used
    if [ "$tokens_total" -gt 0 ]; then
        percentage=$(echo "scale=1; ($tokens_used * 100) / $tokens_total" | bc)
    else
        percentage=0
    fi

    # Estimate input/output split (roughly 70% input, 30% output for typical usage)
    input_tokens=$(echo "scale=0; $tokens_used * 0.7 / 1" | bc)
    output_tokens=$(echo "scale=0; $tokens_used * 0.3 / 1" | bc)

    # Calculate cost
    cost=$(calculate_cost "$input_tokens" "$output_tokens" "$model")

    # Format output with colors for terminal
    if [ -t 1 ]; then
        # Terminal supports colors
        GREEN='\033[0;32m'
        YELLOW='\033[1;33m'
        RED='\033[0;31m'
        BLUE='\033[0;34m'
        NC='\033[0m' # No Color

        # Choose color based on usage percentage
        if (( $(echo "$percentage < 50" | bc -l) )); then
            COLOR=$GREEN
        elif (( $(echo "$percentage < 80" | bc -l) )); then
            COLOR=$YELLOW
        else
            COLOR=$RED
        fi

        echo -e "${BLUE}📊 Claude Code Status${NC} | ${COLOR}${tokens_used}${NC}/${tokens_total} tokens (${COLOR}${percentage}%${NC}) | Remaining: ${tokens_remaining} | ${BLUE}💰 \$${cost}${NC} (GCP Vertex AI)"
    else
        # Plain text output
        echo "📊 Claude Code Status | ${tokens_used}/${tokens_total} tokens (${percentage}%) | Remaining: ${tokens_remaining} | 💰 \$${cost} (GCP Vertex AI)"
    fi
}

# Main execution
main() {
    local model=${1:-"sonnet"}
    local log_file=${2:-}

    # Get token information
    tokens_info=$(parse_tokens "$log_file")

    # Display status
    display_status "$tokens_info" "$model"
}

# Run if executed directly
if [ "${BASH_SOURCE[0]}" == "${0}" ]; then
    main "$@"
fi
