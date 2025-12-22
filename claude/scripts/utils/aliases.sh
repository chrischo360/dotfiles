#!/bin/bash

# Claude Code Aliases
# Source this file in your ~/.zshrc or ~/.bashrc:
#   source $DOTFILES_DIR/claude/aliases.sh

# Quick status check
alias claude-status='$DOTFILES_DIR/claude/status'
alias cs='$DOTFILES_DIR/claude/status'
alias cc-cost='$DOTFILES_DIR/claude/status'

# Check costs for different models quickly
alias opus-cost='$DOTFILES_DIR/claude/status $(echo $CLAUDE_TOKENS_USED | grep -oE "[0-9]+" || echo 0) opus'
alias sonnet-cost='$DOTFILES_DIR/claude/status $(echo $CLAUDE_TOKENS_USED | grep -oE "[0-9]+" || echo 0) sonnet'
alias haiku-cost='$DOTFILES_DIR/claude/status $(echo $CLAUDE_TOKENS_USED | grep -oE "[0-9]+" || echo 0) haiku'

# Add dotfiles/claude to PATH if not already there
if [[ ":$PATH:" != *":$DOTFILES_DIR/claude:"* ]]; then
    export PATH="$DOTFILES_DIR/claude:$PATH"
fi

# Helper function for cost comparison
compare-costs() {
    local tokens=${1:-${CLAUDE_TOKENS_USED:-0}}
    echo "Cost comparison for $tokens tokens:"
    echo ""
    $DOTFILES_DIR/claude/status "$tokens" opus | grep -E "(Token Usage|Est\. Cost)"
    echo ""
    $DOTFILES_DIR/claude/status "$tokens" sonnet | grep -E "(Token Usage|Est\. Cost)"
    echo ""
    $DOTFILES_DIR/claude/status "$tokens" haiku | grep -E "(Token Usage|Est\. Cost)"
}

# Export the function so it's available in the shell
export -f compare-costs 2>/dev/null || true
