#!/bin/bash

# Spam-check PR merge status and merge the instant it's ready
# Auto-updates branch when out-of-date, then merges when checks pass
# Beats auto-merge by immediately firing merge request when checks pass

set -e

echo "Watching PR merge status..."
echo "Press Ctrl+C to cancel"
echo ""

# Get PR number and repo info
PR_NUMBER=$(gh pr view --json number -q .number)
REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner)

while true; do
  STATUS=$(gh pr view --json mergeStateStatus -q .mergeStateStatus)

  # Priority 1: Update if behind
  if [ "$STATUS" = "BEHIND" ]; then
    echo "⚠️  PR is out-of-date. Updating branch..."
    if gh api "repos/$REPO/pulls/$PR_NUMBER/update-branch" -X PUT 2>&1; then
      echo "✓ Branch updated! Waiting for CI checks..."
      terminal-notifier -title "PR Update" -message "Branch updated, waiting for CI checks..." -sound default
    else
      echo "❌ Failed to update branch. Check the error above."
      exit 1
    fi
  # Priority 2: Merge if clean
  elif [ "$STATUS" = "CLEAN" ] || [ "$STATUS" = "HAS_HOOKS" ]; then
    echo "✓ PR is ready! Merging now..."
    gh pr merge --squash
    echo "✓ Merge request sent!"
    terminal-notifier -title "PR Merged" -message "PR successfully merged!" -sound Glass
    break
  else
    echo "⏳ Status: $STATUS - waiting..."
  fi

  sleep 3
done
