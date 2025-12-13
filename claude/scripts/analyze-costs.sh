#!/usr/bin/env zsh
# Claude Code Historical Cost Analysis
# Analyzes transcript files from last 30 days to calculate usage costs

### CONSTANTS
# Pricing per 1M tokens (GCP Vertex AI)
SONNET_INPUT=3.00
SONNET_OUTPUT=15.00
OPUS_INPUT=15.00
OPUS_OUTPUT=75.00
HAIKU_INPUT=0.40
HAIKU_OUTPUT=2.00

# Date threshold (30 days ago in epoch seconds)
CUTOFF_DATE=$(date -v-30d +%s 2>/dev/null || date -d "30 days ago" +%s)

# Colors for terminal output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

### DATA STRUCTURES
declare -A daily_costs
declare -A daily_messages
declare -A daily_input
declare -A daily_output
declare -A daily_cache_read
declare -A model_costs
declare -A model_messages
declare -A model_input
declare -A model_output

### FUNCTIONS

# Map model name to pricing tier
map_model_to_tier() {
    local model_name="$1"

    case "$model_name" in
        *opus-4*)
            echo "opus"
            ;;
        *haiku-4*)
            echo "haiku"
            ;;
        *sonnet-4-5*|*sonnet-4.5*)
            echo "sonnet"
            ;;
        *)
            echo "sonnet"  # Default to sonnet
            ;;
    esac
}

# Calculate cost for a single message
calculate_cost() {
    local input_tokens="$1"
    local cache_creation="$2"
    local output_tokens="$3"
    local model_tier="$4"

    # Billable input = regular input + cache creation (both charged)
    local total_input=$((input_tokens + cache_creation))

    # Get pricing based on tier
    local input_price
    local output_price
    case "$model_tier" in
        "opus")
            input_price=$OPUS_INPUT
            output_price=$OPUS_OUTPUT
            ;;
        "haiku")
            input_price=$HAIKU_INPUT
            output_price=$HAIKU_OUTPUT
            ;;
        *)
            input_price=$SONNET_INPUT
            output_price=$SONNET_OUTPUT
            ;;
    esac

    # Calculate: (tokens / 1M) * price_per_1M
    echo "scale=6; ($total_input * $input_price + $output_tokens * $output_price) / 1000000" | bc
}

# Parse transcript files and extract usage data
parse_transcripts() {
    local cutoff="$1"

    # Process files in parallel for speed (10 concurrent jq processes)
    find ~/.claude/projects -name "*.jsonl" -type f 2>/dev/null | \
    xargs -P 10 -I {} jq -c --argjson cutoff "$cutoff" '
        select(.type == "assistant" and .message.usage != null) |
        select(.timestamp != null) |
        . as $msg |
        ($msg.timestamp | sub("\\.\\d+Z$"; "Z") | fromdateiso8601) as $ts |
        select($ts >= $cutoff) |
        {
            date: ($ts | strftime("%Y-%m-%d")),
            model: $msg.message.model,
            usage: $msg.message.usage
        }
    ' {} 2>/dev/null
}

# Format number with commas
format_number() {
    printf "%'d" "$1" 2>/dev/null || printf "%d" "$1"
}

# Format currency
format_currency() {
    printf "\$%.2f" "$1"
}

# Format large numbers (K/M)
format_large_number() {
    local num="$1"

    if [ "$num" -ge 1000000 ]; then
        echo "$(echo "scale=1; $num / 1000000" | bc)M"
    elif [ "$num" -ge 1000 ]; then
        echo "$(echo "scale=0; $num / 1000" | bc)K"
    else
        echo "$num"
    fi
}

# Main execution
main() {
    echo -e "${CYAN}=================================================================${NC}"
    echo -e "${CYAN}          Claude Code Cost Analysis - Last 30 Days${NC}"
    echo -e "${CYAN}=================================================================${NC}"
    echo ""
    echo -e "${BLUE}Analyzing transcript files...${NC}"

    # Parse all transcripts and accumulate data
    local total_messages=0
    local total_input=0
    local total_output=0
    local total_cache_read=0
    local total_cost=0

    while IFS= read -r json_line; do
        [ -z "$json_line" ] && continue

        # Extract fields
        date=$(echo "$json_line" | jq -r '.date // "unknown"')
        model=$(echo "$json_line" | jq -r '.model // "unknown"')

        # Skip if date is invalid
        [[ "$date" == "unknown" ]] && continue

        # Extract token counts
        input=$(echo "$json_line" | jq -r '.usage.input_tokens // 0')
        cache_creation=$(echo "$json_line" | jq -r '.usage.cache_creation_input_tokens // 0')
        cache_read=$(echo "$json_line" | jq -r '.usage.cache_read_input_tokens // 0')
        output=$(echo "$json_line" | jq -r '.usage.output_tokens // 0')

        # Calculate cost for this message
        tier=$(map_model_to_tier "$model")
        cost=$(calculate_cost "$input" "$cache_creation" "$output" "$tier")

        # Accumulate by date
        daily_costs["$date"]=$(echo "${daily_costs[$date]:-0} + $cost" | bc)
        daily_messages["$date"]=$((${daily_messages[$date]:-0} + 1))
        daily_input["$date"]=$((${daily_input[$date]:-0} + input + cache_creation))
        daily_output["$date"]=$((${daily_output[$date]:-0} + output))
        daily_cache_read["$date"]=$((${daily_cache_read[$date]:-0} + cache_read))

        # Accumulate by model tier
        model_costs["$tier"]=$(echo "${model_costs[$tier]:-0} + $cost" | bc)
        model_messages["$tier"]=$((${model_messages[$tier]:-0} + 1))
        model_input["$tier"]=$((${model_input[$tier]:-0} + input + cache_creation))
        model_output["$tier"]=$((${model_output[$tier]:-0} + output))

        # Accumulate totals
        total_messages=$((total_messages + 1))
        total_input=$((total_input + input + cache_creation))
        total_output=$((total_output + output))
        total_cache_read=$((total_cache_read + cache_read))
        total_cost=$(echo "$total_cost + $cost" | bc)

    done < <(parse_transcripts "$CUTOFF_DATE")

    echo -e "${GREEN}Found $total_messages messages across ${#daily_costs[@]} days${NC}"
    echo ""

    # Daily Breakdown
    echo -e "${BLUE}Daily Breakdown:${NC}"
    echo "─────────────────────────────────────────────────────────────────"
    printf "%-12s %10s %15s %15s %12s\n" "Date" "Messages" "Input Tokens" "Output Tokens" "Cost"
    echo "─────────────────────────────────────────────────────────────────"

    for date in $(echo "${!daily_costs[@]}" | tr ' ' '\n' | sort); do
        printf "%-12s %10d %15s %15s %12s\n" \
            "$date" \
            "${daily_messages[$date]}" \
            "$(format_number ${daily_input[$date]})" \
            "$(format_number ${daily_output[$date]})" \
            "$(format_currency ${daily_costs[$date]})"
    done

    echo "─────────────────────────────────────────────────────────────────"
    echo ""

    # Model Breakdown
    echo -e "${BLUE}Model Breakdown:${NC}"
    echo "─────────────────────────────────────────────────────────────────"
    printf "%-15s %10s %15s %15s %12s\n" "Model" "Messages" "Input" "Output" "Cost"
    echo "─────────────────────────────────────────────────────────────────"

    for tier in sonnet opus haiku; do
        if [ "${model_messages[$tier]:-0}" -gt 0 ]; then
            local model_name
            case "$tier" in
                "sonnet") model_name="Sonnet 4.5" ;;
                "opus") model_name="Opus 4" ;;
                "haiku") model_name="Haiku 4" ;;
            esac

            printf "%-15s %10d %15s %15s %12s\n" \
                "$model_name" \
                "${model_messages[$tier]}" \
                "$(format_large_number ${model_input[$tier]})" \
                "$(format_large_number ${model_output[$tier]})" \
                "$(format_currency ${model_costs[$tier]})"
        fi
    done

    echo "─────────────────────────────────────────────────────────────────"
    echo ""

    # Monthly Total
    echo -e "${CYAN}═════════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}                        Monthly Total${NC}"
    echo -e "${CYAN}═════════════════════════════════════════════════════════════════${NC}"
    printf "Total Messages:     %s\n" "$(format_number $total_messages)"
    printf "Total Input Tokens: %s\n" "$(format_number $total_input)"
    printf "Total Output Tokens: %s\n" "$(format_number $total_output)"
    printf "Cache Read Tokens:  %s ${GREEN}(FREE)${NC}\n" "$(format_number $total_cache_read)"
    echo ""
    printf "${YELLOW}Total Cost:         %s${NC}\n" "$(format_currency $total_cost)"
    echo -e "${CYAN}═════════════════════════════════════════════════════════════════${NC}"
}

# Run main function
main
