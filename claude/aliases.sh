#!/bin/bash

# Claude Code Aliases
# Source this file in your ~/.zshrc or ~/.bashrc:
#   source ~/dotfiles/claude/aliases.sh

# Quick status check
alias claude-status='~/dotfiles/claude/status'
alias cs='~/dotfiles/claude/status'
alias cc-cost='~/dotfiles/claude/status'

# Check costs for different models quickly
alias opus-cost='~/dotfiles/claude/status $(echo $CLAUDE_TOKENS_USED | grep -oE "[0-9]+" || echo 0) opus'
alias sonnet-cost='~/dotfiles/claude/status $(echo $CLAUDE_TOKENS_USED | grep -oE "[0-9]+" || echo 0) sonnet'
alias haiku-cost='~/dotfiles/claude/status $(echo $CLAUDE_TOKENS_USED | grep -oE "[0-9]+" || echo 0) haiku'

# Add dotfiles/claude to PATH if not already there
if [[ ":$PATH:" != *":$HOME/dotfiles/claude:"* ]]; then
    export PATH="$HOME/dotfiles/claude:$PATH"
fi

# Helper function for cost comparison
compare-costs() {
    local tokens=${1:-${CLAUDE_TOKENS_USED:-0}}
    echo "Cost comparison for $tokens tokens:"
    echo ""
    ~/dotfiles/claude/status "$tokens" opus | grep -E "(Token Usage|Est\. Cost)"
    echo ""
    ~/dotfiles/claude/status "$tokens" sonnet | grep -E "(Token Usage|Est\. Cost)"
    echo ""
    ~/dotfiles/claude/status "$tokens" haiku | grep -E "(Token Usage|Est\. Cost)"
}

# Export the function so it's available in the shell
export -f compare-costs 2>/dev/null || true
