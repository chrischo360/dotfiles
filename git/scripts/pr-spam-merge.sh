#!/bin/bash

# Spam-check PR merge status and merge the instant it's ready
# Auto-updates branch when out-of-date, then merges when checks pass
# Beats auto-merge by immediately firing merge request when checks pass
# Usage: pr-spam-merge [PR_NUMBER]

set -e

echo "Watching PR merge status..."
echo "Press Ctrl+C to cancel"
echo ""

REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner)

# Use provided PR number or detect from current branch
if [ -n "$1" ]; then
  PR_NUMBER=$1
else
  PR_NUMBER=$(gh pr view --json number -q .number)
fi

echo "Watching PR #$PR_NUMBER..."

while true; do
  STATUS=$(gh pr view "$PR_NUMBER" --json mergeStateStatus -q .mergeStateStatus)

  # Priority 1: Update if behind
  if [ "$STATUS" = "BEHIND" ]; then
    echo "⚠️  PR is out-of-date. Updating branch..."
    if gh api "repos/$REPO/pulls/$PR_NUMBER/update-branch" -X PUT 2>&1; then
      echo "✓ Branch updated! Waiting for CI checks..."
      terminal-notifier -title "PR #$PR_NUMBER Update" -message "Branch updated, waiting for CI checks..." -sound default
    else
      echo "❌ Failed to update branch. Check the error above."
      exit 1
    fi
  # Priority 2: Merge if clean
  elif [ "$STATUS" = "CLEAN" ] || [ "$STATUS" = "HAS_HOOKS" ]; then
    echo "✓ PR is ready! Merging now..."
    gh pr merge "$PR_NUMBER" --squash
    echo "✓ Merge request sent!"
    terminal-notifier -title "PR #$PR_NUMBER Merged" -message "PR #$PR_NUMBER successfully merged!" -sound Glass
    break
  else
    echo "⏳ Status: $STATUS - waiting..."
  fi

  sleep 3
done
