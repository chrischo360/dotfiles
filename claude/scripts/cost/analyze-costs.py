#!/usr/bin/env python3
"""
Claude Code Historical Cost Analysis
Analyzes transcript files from last 30 days to calculate usage costs
"""

import json
import glob
import os
from datetime import datetime, timedelta, timezone
from collections import defaultdict

# Colors for terminal output
CYAN = '\033[0;36m'
BLUE = '\033[0;34m'
GREEN = '\033[0;32m'
YELLOW = '\033[1;33m'
NC = '\033[0m'  # No Color

# GCP Vertex AI pricing (per 1M tokens)
PRICING = {
    'sonnet': {'input': 3.00, 'output': 15.00},
    'opus': {'input': 15.00, 'output': 75.00},
    'haiku': {'input': 0.40, 'output': 2.00}
}

SWITCH_DATE = '2026-02-25'

def map_model_to_tier(model_name):
    """Map model name to pricing tier"""
    if 'opus-4' in model_name:
        return 'opus'
    elif 'haiku-4' in model_name:
        return 'haiku'
    else:
        return 'sonnet'

def model_display_name(model_name):
    """Get display name for a model"""
    if 'sonnet-4-6' in model_name:
        return 'Sonnet 4.6'
    elif 'sonnet-4-5' in model_name:
        return 'Sonnet 4.5'
    elif 'opus-4-6' in model_name or 'opus-4@' not in model_name and 'opus-4' in model_name:
        return 'Opus 4.6' if '4-6' in model_name else 'Opus 4'
    elif 'haiku-4' in model_name:
        return 'Haiku 4'
    return model_name

def calculate_cost(input_tokens, cache_creation, output_tokens, tier):
    """Calculate cost for a message"""
    total_input = input_tokens + cache_creation
    prices = PRICING[tier]

    cost = (total_input * prices['input'] + output_tokens * prices['output']) / 1_000_000
    return cost

def format_number(num):
    """Format number with commas"""
    return f"{num:,}"

def format_currency(amount):
    """Format currency"""
    return f"${amount:.2f}"

def format_large_number(num):
    """Format large numbers with K/M suffix"""
    if num >= 1_000_000:
        return f"{num/1_000_000:.1f}M"
    elif num >= 1_000:
        return f"{num/1_000:.0f}K"
    else:
        return str(num)

def main():
    print(f"{CYAN}================================================================={NC}")
    print(f"{CYAN}          Claude Code Cost Analysis - Last 30 Days{NC}")
    print(f"{CYAN}================================================================={NC}")
    print()
    print(f"{BLUE}Analyzing transcript files...{NC}")

    # Date threshold (30 days ago)
    cutoff = datetime.now(timezone.utc) - timedelta(days=30)

    # Data structures
    daily_costs = defaultdict(float)
    daily_messages = defaultdict(int)
    daily_input = defaultdict(int)
    daily_output = defaultdict(int)
    daily_cache_read = defaultdict(int)

    model_costs = defaultdict(float)
    model_messages = defaultdict(int)
    model_input = defaultdict(int)
    model_output = defaultdict(int)

    period_costs = {'before': defaultdict(float), 'after': defaultdict(float)}
    period_messages = {'before': defaultdict(int), 'after': defaultdict(int)}

    total_messages = 0
    total_input = 0
    total_output = 0
    total_cache_read = 0
    total_cost = 0.0

    # Find all transcript files
    transcript_pattern = os.path.expanduser('~/.claude/projects/**/*.jsonl')
    files = glob.glob(transcript_pattern, recursive=True)

    # Process each file
    for file_path in files:
        try:
            with open(file_path, 'r') as f:
                for line in f:
                    if not line.strip():
                        continue

                    try:
                        msg = json.loads(line)

                        # Check if it's an assistant message with usage
                        if msg.get('type') != 'assistant':
                            continue
                        if not msg.get('message', {}).get('usage'):
                            continue
                        if not msg.get('timestamp'):
                            continue

                        # Parse timestamp
                        timestamp_str = msg['timestamp'].replace('Z', '+00:00')
                        ts = datetime.fromisoformat(timestamp_str)

                        # Filter by date
                        if ts < cutoff:
                            continue

                        # Extract usage data
                        usage = msg['message']['usage']
                        model = msg['message'].get('model', 'unknown')

                        input_tokens = usage.get('input_tokens', 0)
                        cache_creation = usage.get('cache_creation_input_tokens', 0)
                        cache_read = usage.get('cache_read_input_tokens', 0)
                        output_tokens = usage.get('output_tokens', 0)

                        # Calculate cost
                        tier = map_model_to_tier(model)
                        cost = calculate_cost(input_tokens, cache_creation, output_tokens, tier)

                        # Accumulate by date
                        date_str = ts.strftime('%Y-%m-%d')
                        daily_costs[date_str] += cost
                        daily_messages[date_str] += 1
                        daily_input[date_str] += input_tokens + cache_creation
                        daily_output[date_str] += output_tokens
                        daily_cache_read[date_str] += cache_read

                        # Accumulate by model (using actual model name)
                        display = model_display_name(model)
                        model_costs[display] += cost
                        model_messages[display] += 1
                        model_input[display] += input_tokens + cache_creation
                        model_output[display] += output_tokens

                        # Accumulate by period (before/after switch date)
                        period = 'after' if date_str >= SWITCH_DATE else 'before'
                        period_costs[period][date_str] += cost
                        period_messages[period][date_str] += 1

                        # Accumulate totals
                        total_messages += 1
                        total_input += input_tokens + cache_creation
                        total_output += output_tokens
                        total_cache_read += cache_read
                        total_cost += cost

                    except (json.JSONDecodeError, KeyError, ValueError, TypeError):
                        # Skip malformed lines
                        continue

        except (IOError, OSError):
            # Skip files we can't read
            continue

    print(f"{GREEN}Found {total_messages} messages across {len(daily_costs)} days{NC}")
    print()

    # Daily Breakdown
    print(f"{BLUE}Daily Breakdown:{NC}")
    print("─────────────────────────────────────────────────────────────────")
    print(f"{'Date':<12} {'Messages':>10} {'Input Tokens':>15} {'Output Tokens':>15} {'Cost':>12}")
    print("─────────────────────────────────────────────────────────────────")

    for date in sorted(daily_costs.keys()):
        print(f"{date:<12} {daily_messages[date]:>10} {format_number(daily_input[date]):>15} "
              f"{format_number(daily_output[date]):>15} {format_currency(daily_costs[date]):>12}")

    print("─────────────────────────────────────────────────────────────────")
    print()

    # Model Breakdown
    print(f"{BLUE}Model Breakdown:{NC}")
    print("─────────────────────────────────────────────────────────────────")
    print(f"{'Model':<15} {'Messages':>10} {'Input':>15} {'Output':>15} {'Cost':>12}")
    print("─────────────────────────────────────────────────────────────────")

    for display in sorted(model_messages.keys()):
        if model_messages[display] > 0:
            print(f"{display:<15} {model_messages[display]:>10} "
                  f"{format_large_number(model_input[display]):>15} "
                  f"{format_large_number(model_output[display]):>15} "
                  f"{format_currency(model_costs[display]):>12}")

    print("─────────────────────────────────────────────────────────────────")
    print()

    # Before/After Feb 25 Comparison
    print(f"{BLUE}Before vs After {SWITCH_DATE} (Sonnet 4.6 switch):{NC}")
    print("─────────────────────────────────────────────────────────────────")
    print(f"{'Date':<12} {'Period':<10} {'Messages':>10} {'Cost':>12} {'$/msg':>10}")
    print("─────────────────────────────────────────────────────────────────")

    before_total_cost = sum(period_costs['before'].values())
    before_total_msgs = sum(period_messages['before'].values())
    after_total_cost = sum(period_costs['after'].values())
    after_total_msgs = sum(period_messages['after'].values())

    for date in sorted(period_costs['before'].keys()):
        c = period_costs['before'][date]
        m = period_messages['before'][date]
        cpp = c / m if m else 0
        print(f"{date:<12} {'before':<10} {m:>10} {format_currency(c):>12} {format_currency(cpp):>10}")

    print(f"{'TOTAL':<12} {'before':<10} {before_total_msgs:>10} {format_currency(before_total_cost):>12} "
          f"{format_currency(before_total_cost/before_total_msgs if before_total_msgs else 0):>10}")
    print()

    for date in sorted(period_costs['after'].keys()):
        c = period_costs['after'][date]
        m = period_messages['after'][date]
        cpp = c / m if m else 0
        print(f"{date:<12} {'after':<10} {m:>10} {format_currency(c):>12} {format_currency(cpp):>10}")

    print(f"{'TOTAL':<12} {'after':<10} {after_total_msgs:>10} {format_currency(after_total_cost):>12} "
          f"{format_currency(after_total_cost/after_total_msgs if after_total_msgs else 0):>10}")
    print("─────────────────────────────────────────────────────────────────")
    print()

    # Monthly Total
    print(f"{CYAN}═════════════════════════════════════════════════════════════════{NC}")
    print(f"{CYAN}                        Monthly Total{NC}")
    print(f"{CYAN}═════════════════════════════════════════════════════════════════{NC}")
    print(f"Total Messages:     {format_number(total_messages)}")
    print(f"Total Input Tokens: {format_number(total_input)}")
    print(f"Total Output Tokens: {format_number(total_output)}")
    print(f"Cache Read Tokens:  {format_number(total_cache_read)} {GREEN}(FREE){NC}")
    print()
    print(f"{YELLOW}Total Cost:         {format_currency(total_cost)}{NC}")
    print(f"{CYAN}═════════════════════════════════════════════════════════════════{NC}")

if __name__ == '__main__':
    main()
