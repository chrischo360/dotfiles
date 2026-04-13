# PR Notification Monitor

Manage the GitHub PR notification system that watches for new review comments and CI/CD failures across all your open PRs.

## Instructions

Run the appropriate command based on user intent:

### Show PR status dashboard (default)
```bash
~/dotfiles/claude/scripts/monitoring/gh-pr-notify.sh --status
```

### Check now (send notifications for new events)
```bash
~/dotfiles/claude/scripts/monitoring/gh-pr-notify.sh --once
```

### Show recent notifications
```bash
tail -30 /tmp/gh-pr-notify.log
```

### Start background daemon
```bash
# Install launchd agent
cp ~/dotfiles/claude/scripts/monitoring/com.user.gh-pr-notify.plist ~/Library/LaunchAgents/
launchctl load ~/Library/LaunchAgents/com.user.gh-pr-notify.plist
echo "PR notify daemon started (polls every 5 minutes)"
```

### Stop background daemon
```bash
launchctl unload ~/Library/LaunchAgents/com.user.gh-pr-notify.plist
echo "PR notify daemon stopped"
```

### Check daemon status
```bash
launchctl list | grep gh-pr-notify
```

### Reset state (re-notify everything)
```bash
~/dotfiles/claude/scripts/monitoring/gh-pr-notify.sh --reset --once
```

### Dry run (preview without notifying)
```bash
~/dotfiles/claude/scripts/monitoring/gh-pr-notify.sh --once --dry-run
```

Ask the user what they want to do if unclear. Default to `--status` to show the dashboard.
