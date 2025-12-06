# Nvim Memory Monitoring with Daily Notifications

## Overview

Automatically monitors nvim and LSP memory usage and sends you a daily macOS notification at **11 AM EST**.

**No automatic killing** - you stay in control and manually run cleanup when needed.

## What It Does

### Daily at 11 AM EST:
1. Runs `nvim-process-report.sh` to analyze all nvim/LSP processes
2. Extracts memory usage summary
3. Sends macOS notification with:
   - **Title:** "📊 Nvim Memory Report"
   - **Message:** "5 nvim (228 MB) + 3 LSP (1575 MB) = 1.77 GB total"
   - **Click action:** Opens full detailed report
4. Logs full report to `~/.local/log/nvim-memory-report.log`

### Alert Levels:
- **Normal** (< 3 GB): "📊 Nvim Memory Report"
- **Warning** (3-5 GB): "⚠️  Nvim Memory Warning" (Funk sound)
- **Critical** (> 5 GB): "🚨 Nvim Memory Alert - HIGH" (Basso sound)

## Files

- **Notification Script:** `~/dotfiles/scripts/nvim-memory-notify.sh`
- **Report Script:** `~/dotfiles/scripts/nvim-process-report.sh`
- **Cleanup Script:** `~/dotfiles/scripts/cleanup-old-nvim.sh` (manual use)
- **LaunchAgent:** `~/dotfiles/launchd/com.user.nvim-memory-monitor.plist`
- **Report Log:** `~/.local/log/nvim-memory-report.log`
- **Monitor Log:** `~/.local/log/nvim-memory-monitor.log`

## Installation

### 1. Ensure Scripts are Executable
```bash
chmod +x ~/dotfiles/scripts/nvim-memory-notify.sh
chmod +x ~/dotfiles/scripts/nvim-process-report.sh
chmod +x ~/dotfiles/scripts/cleanup-old-nvim.sh
```

### 2. Create Log Directory
```bash
mkdir -p ~/.local/log
```

### 3. Install LaunchAgent
```bash
# If you have the old cleanup LaunchAgent, unload it first
launchctl unload ~/Library/LaunchAgents/com.user.cleanup-nvim.plist 2>/dev/null

# Install new monitoring LaunchAgent
cp ~/dotfiles/launchd/com.user.nvim-memory-monitor.plist ~/Library/LaunchAgents/

# Load it (will run at next 11 AM, or at login)
launchctl load ~/Library/LaunchAgents/com.user.nvim-memory-monitor.plist

# Verify it's loaded
launchctl list | grep nvim-memory-monitor
```

### 4. Test It Works
```bash
# Trigger notification manually
~/dotfiles/scripts/nvim-memory-notify.sh

# Check if you received notification
# Check log file
tail ~/.local/log/nvim-memory-report.log
```

## Usage

### Manual Trigger
```bash
# Run report and get notification now
~/dotfiles/scripts/nvim-memory-notify.sh

# View last report
tail -100 ~/.local/log/nvim-memory-report.log

# Full detailed report in terminal
~/dotfiles/scripts/nvim-process-report.sh
```

### When You Get a Notification

1. **Click the notification** to view full detailed report
2. Review memory usage and directories
3. Decide if cleanup is needed
4. **Manual cleanup** if desired:
   ```bash
   # Dry run first
   ~/dotfiles/scripts/cleanup-old-nvim.sh --dry-run

   # Actually clean up processes older than 2 days
   ~/dotfiles/scripts/cleanup-old-nvim.sh

   # Or just kill idle processes
   ~/dotfiles/scripts/cleanup-old-nvim.sh --idle-only
   ```

## Workflow

### Daily Routine
1. **11 AM:** Receive notification
2. **Review:** Click to see which directories are using memory
3. **Decide:**
   - Normal usage? Ignore it
   - High usage? Run cleanup script
   - Specific instance causing issues? Kill it manually

### Weekly Cleanup
```bash
# Check current status
~/dotfiles/scripts/nvim-process-report.sh

# Clean up anything older than 2 days
~/dotfiles/scripts/cleanup-old-nvim.sh --dry-run
~/dotfiles/scripts/cleanup-old-nvim.sh
```

### Emergency (System Slow)
```bash
# Quick check
~/dotfiles/scripts/nvim-process-report.sh --summary

# Kill processes older than 6 hours
~/dotfiles/scripts/cleanup-old-nvim.sh 6
```

## Recommended Aliases

Add to `~/.zshrc`:

```bash
# Monitoring
alias nvim-report='~/dotfiles/scripts/nvim-process-report.sh'
alias nvim-summary='~/dotfiles/scripts/nvim-process-report.sh --summary'
alias nvim-notify='~/dotfiles/scripts/nvim-memory-notify.sh'

# Cleanup (manual)
alias cleanup-nvim='~/dotfiles/scripts/cleanup-old-nvim.sh'
alias cleanup-nvim-dry='~/dotfiles/scripts/cleanup-old-nvim.sh --dry-run'
alias cleanup-nvim-idle='~/dotfiles/scripts/cleanup-old-nvim.sh --idle-only'
```

## What Happens When Computer is Off at 11 AM?

The LaunchAgent has **RunAtLoad** enabled:

- **Computer ON at 11 AM:** Notification runs as scheduled
- **Computer OFF at 11 AM:**
  - Next time you login/boot → notification runs
  - Then resumes daily 11 AM schedule

You'll always get at least one notification per day when you're using your computer.

## Notification Examples

### Normal Usage
```
📊 Nvim Memory Report
Click to view detailed report
5 nvim (228 MB) + 3 LSP (1575 MB) = 1.77 GB total
```

### Warning
```
⚠️  Nvim Memory Warning
Click to view detailed report
8 nvim (450 MB) + 5 LSP (3200 MB) = 3.65 GB total
```

### Critical
```
🚨 Nvim Memory Alert - HIGH
Click to view detailed report
12 nvim (800 MB) + 8 LSP (5400 MB) = 6.2 GB total
```

## Log File Management

The report log at `~/.local/log/nvim-memory-report.log`:
- Automatically limited to last 10,000 lines
- Keeps approximately 30 days of history
- Includes timestamp for each report

View recent reports:
```bash
# Last 100 lines
tail -100 ~/.local/log/nvim-memory-report.log

# Today's reports
grep "$(date '+%Y-%m-%d')" ~/.local/log/nvim-memory-report.log

# Search for high memory days
grep -B2 "GB total" ~/.local/log/nvim-memory-report.log | grep "GRAND TOTAL"
```

## Troubleshooting

### No Notification Received
```bash
# Check if LaunchAgent is loaded
launchctl list | grep nvim-memory-monitor

# Check monitor log for errors
cat ~/.local/log/nvim-memory-monitor-error.log

# Manually trigger to test
~/dotfiles/scripts/nvim-memory-notify.sh
```

### Notification Doesn't Open Log File
```bash
# Check if log exists
ls -lh ~/.local/log/nvim-memory-report.log

# Open manually
open ~/.local/log/nvim-memory-report.log
```

### Want to Change Schedule
Edit `~/dotfiles/launchd/com.user.nvim-memory-monitor.plist`:

```xml
<!-- Change hour (0-23, local time) -->
<key>Hour</key>
<integer>11</integer>  <!-- Change this -->

<!-- Add day of week (optional: 1=Monday, 7=Sunday) -->
<key>Weekday</key>
<integer>1</integer>  <!-- Only run on Mondays -->
```

Then reload:
```bash
launchctl unload ~/Library/LaunchAgents/com.user.nvim-memory-monitor.plist
launchctl load ~/Library/LaunchAgents/com.user.nvim-memory-monitor.plist
```

### Disable Monitoring
```bash
# Temporarily disable
launchctl unload ~/Library/LaunchAgents/com.user.nvim-memory-monitor.plist

# Re-enable
launchctl load ~/Library/LaunchAgents/com.user.nvim-memory-monitor.plist

# Permanently remove
launchctl unload ~/Library/LaunchAgents/com.user.nvim-memory-monitor.plist
rm ~/Library/LaunchAgents/com.user.nvim-memory-monitor.plist
```

## Manual Cleanup Reference

When notification shows high memory, use cleanup script:

```bash
# See what would be killed (2+ days old)
cleanup-old-nvim --dry-run

# Actually kill them
cleanup-old-nvim

# Kill processes older than 1 day
cleanup-old-nvim 24

# Kill only idle processes (2+ days old, < 2 min CPU time)
cleanup-old-nvim --idle-only

# Emergency: kill everything older than 6 hours
cleanup-old-nvim 6
```

See [cleanup-nvim-README.md](./cleanup-nvim-README.md) for full cleanup documentation.

## Privacy & Performance

- Scripts run in user space (no sudo required)
- Minimal CPU usage (< 1 second per run)
- Log files auto-managed (won't grow forever)
- Only monitors your own processes
- No data sent externally

## Example Daily Workflow

**11:05 AM** - Notification arrives:
```
📊 Nvim Memory Report
5 nvim (228 MB) + 3 LSP (1575 MB) = 1.77 GB total
```

**Action:**
- Total < 2 GB → ✅ All good, ignore notification
- Total 2-3 GB → 👀 Click to see details, maybe cleanup
- Total > 3 GB → ⚠️ Definitely review and cleanup

**If cleanup needed:**
```bash
# Quick check
nvim-report

# See what's old
cleanup-nvim-dry

# Clean it up
cleanup-nvim
```

---

**Remember:** This system **never auto-kills** processes. You're always in control!
