# Nvim & LSP Process Monitoring & Cleanup Guide

## Overview

Two scripts to help manage memory usage from nvim and LSP servers:

1. **`nvim-process-report.sh`** - Shows all nvim, node, and LSP processes with memory and directories
2. **`cleanup-old-nvim.sh`** - Automatically kills old/idle nvim instances and LSP servers

## 1. Process Report Script

### Usage

```bash
# Full detailed report
~/dotfiles/scripts/nvim-process-report.sh

# Summary only (totals)
~/dotfiles/scripts/nvim-process-report.sh --summary
```

### What It Shows

**For Each Nvim Instance:**
- Process ID (PID)
- Memory usage (MB)
- CPU time used
- When it was started
- **Working directory** (where nvim is running)
- Child LSP servers

**For Each LSP Server:**
- Type (Intelephense, TypeScript LS, Pyright, etc.)
- Process ID and parent process
- Memory usage (MB)
- **Working directory**
- Orphan status (if parent nvim died)

**For Each Node Process:**
- Process ID
- Memory usage (MB)
- Command being run
- **Working directory**

**Grand Totals:**
- Total nvim instances and memory
- Total LSP servers and memory
- Total other node processes and memory
- Combined total

### Example Output

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📊 NVIM & LSP PROCESS REPORT
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃ 1. NVIM INSTANCES                                          ┃
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

  PID: 18743
    Memory:    34 MB
    CPU Time:  0:03.28
    Started:   Sat Dec 6 17:39:05 2025
    Directory: /Users/cc446g/codebase/php
    LSP Servers:
      • Intelephense (PHP) (PID 18827): 1133 MB

  PID: 33605
    Memory:    56 MB
    CPU Time:  0:05.11
    Started:   Sat Dec 6 17:41:05 2025
    Directory: /Users/cc446g/notes

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📈 TOTAL MEMORY USAGE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Nvim instances:      5 processes → 268 MB
  LSP servers:         2 processes → 1148 MB
  Other node:          3 processes → 15 MB

  GRAND TOTAL:         1431 MB (~1.39 GB)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Quick Aliases

Add to `~/.zshrc`:

```bash
alias nvim-report='~/dotfiles/scripts/nvim-process-report.sh'
alias nvim-summary='~/dotfiles/scripts/nvim-process-report.sh --summary'
```

Then:
```bash
nvim-report    # Full report
nvim-summary   # Quick summary
```

## 2. Cleanup Script

See [cleanup-nvim-README.md](./cleanup-nvim-README.md) for full details.

### Quick Usage

```bash
# Kill processes older than 2 days (48 hours)
~/dotfiles/scripts/cleanup-old-nvim.sh

# Kill only idle processes (2+ days old with < 2 min CPU time)
~/dotfiles/scripts/cleanup-old-nvim.sh --idle-only

# Dry run first
~/dotfiles/scripts/cleanup-old-nvim.sh --dry-run
```

## LaunchAgent: What Happens When Computer Is Off?

### How It Works

The LaunchAgent has **3 mechanisms** to ensure cleanup runs:

#### 1. **Scheduled Time (2 AM Daily)**
```xml
<key>StartCalendarInterval</key>
<dict>
    <key>Hour</key>
    <integer>2</integer>
    <key>Minute</key>
    <integer>0</integer>
</dict>
```

**Behavior:**
- ✅ Runs at 2 AM if computer is **ON**
- ❌ **DOES NOT** run if computer is **OFF/ASLEEP**
- ❌ **DOES NOT** catch up when computer wakes

#### 2. **Run at System Load**
```xml
<key>RunAtLoad</key>
<true/>
```

**Behavior:**
- ✅ Runs when LaunchAgent is **first loaded**
- ✅ Runs when you **login** after boot
- ✅ Runs when you **reload** the LaunchAgent

**This means:**
- If your computer was off at 2 AM
- When you login the next day
- **It will run automatically** to catch up

#### 3. **Periodic Interval (Every 24 Hours)**
```xml
<key>StartInterval</key>
<integer>86400</integer>
```

**Behavior:**
- ✅ Runs every 24 hours **while computer is awake**
- ✅ **Catches up** if computer was asleep
- ✅ Ensures cleanup happens at least once per day

### Scenarios

#### Scenario 1: Computer On at 2 AM
- ✅ Cleanup runs at 2 AM
- ✅ Next scheduled run: Tomorrow at 2 AM

#### Scenario 2: Computer Off at 2 AM
- ❌ Scheduled 2 AM run is **missed**
- ✅ When you login next day (e.g., 9 AM):
  - `RunAtLoad` triggers cleanup
- ✅ Cleanup runs
- ✅ Next interval: 24 hours from now (9 AM tomorrow)

#### Scenario 3: Computer Sleeps at 2 AM
- ❌ Scheduled 2 AM run is **missed**
- ✅ When computer wakes up:
  - `StartInterval` catches up within 24 hours
- ✅ Cleanup runs when you're active

#### Scenario 4: Computer On 24/7
- ✅ Runs at 2 AM every day reliably
- ✅ `StartInterval` has no effect (already ran via calendar)

### How to Check If It's Working

```bash
# Check if LaunchAgent is loaded
launchctl list | grep cleanup-nvim

# View recent executions
log show --predicate 'processImagePath CONTAINS "cleanup-old-nvim"' --last 7d --info

# Check log files
tail -f ~/.local/log/cleanup-nvim.log

# See last run time
stat -f "%Sm" ~/.local/log/cleanup-nvim.log
```

### Force Manual Run

```bash
# Trigger the LaunchAgent immediately
launchctl start com.user.cleanup-nvim

# Or just run the script directly
~/dotfiles/scripts/cleanup-old-nvim.sh
```

## Typical Workflow

### Morning Routine
```bash
# Check what's using memory
nvim-summary

# If memory is high, check details
nvim-report

# If you see old processes, clean them up
cleanup-nvim --dry-run     # See what would be killed
cleanup-nvim               # Actually kill them
```

### End of Day
```bash
# Quick check before shutdown
nvim-summary

# Clean up if needed
cleanup-nvim 12  # Kill anything older than 12 hours
```

### Weekly Maintenance
```bash
# Full report
nvim-report > ~/nvim-usage-report.txt

# Review and clean up idle processes
cleanup-nvim --idle-only --dry-run
cleanup-nvim --idle-only
```

## Memory Targets

Based on your current usage:

**Current State (from your report):**
- Nvim instances: 5 processes → 268 MB
- LSP servers: 2 processes → 1148 MB
- Other node: 3 processes → 15 MB
- **Total: ~1.4 GB**

**After Cleanup (target):**
- Nvim instances: 2-3 active → 100-150 MB
- LSP servers: 1-2 active → 500-1000 MB
- Other node: 1-2 active → 10 MB
- **Target: ~600-1100 MB**

**Memory Saved: ~300-800 MB**

### High Memory Indicators

🚨 **Warning Signs:**
- Total > 3 GB
- Intelephense > 2 GB (per instance)
- More than 5 nvim instances
- Nvim processes older than 2 days

🆘 **Emergency:**
- Total > 5 GB
- System memory pressure
- Swap being used heavily

**Action:** Run `cleanup-nvim 6` to kill anything older than 6 hours

## Installation

### 1. Make Scripts Executable
```bash
chmod +x ~/dotfiles/scripts/nvim-process-report.sh
chmod +x ~/dotfiles/scripts/cleanup-old-nvim.sh
```

### 2. Add Aliases to ~/.zshrc
```bash
# Add to ~/.zshrc
alias nvim-report='~/dotfiles/scripts/nvim-process-report.sh'
alias nvim-summary='~/dotfiles/scripts/nvim-process-report.sh --summary'
alias cleanup-nvim='~/dotfiles/scripts/cleanup-old-nvim.sh'
alias cleanup-nvim-dry='~/dotfiles/scripts/cleanup-old-nvim.sh --dry-run'
```

### 3. Install LaunchAgent
```bash
# Create log directory
mkdir -p ~/.local/log

# Install LaunchAgent
cp ~/dotfiles/launchd/com.user.cleanup-nvim.plist ~/Library/LaunchAgents/

# Load it
launchctl load ~/Library/LaunchAgents/com.user.cleanup-nvim.plist

# Verify
launchctl list | grep cleanup-nvim
```

### 4. Test It Works
```bash
# Test the report
nvim-summary

# Test cleanup (dry run)
cleanup-nvim --dry-run

# Check LaunchAgent logs
tail ~/.local/log/cleanup-nvim.log
```

## Troubleshooting

### "No such file or directory" errors
```bash
# Make scripts executable
chmod +x ~/dotfiles/scripts/*.sh
```

### LaunchAgent not running
```bash
# Unload and reload
launchctl unload ~/Library/LaunchAgents/com.user.cleanup-nvim.plist
launchctl load ~/Library/LaunchAgents/com.user.cleanup-nvim.plist
```

### Can't see working directories
```bash
# macOS may restrict lsof access
# Run with sudo (not recommended for LaunchAgent)
sudo ~/dotfiles/scripts/nvim-process-report.sh

# Or grant Terminal/iTerm2 Full Disk Access:
# System Settings → Privacy & Security → Full Disk Access → Add Terminal
```

### Intelephense using too much memory
See your nvim LSP config:
- Excluded directories in `~/dotfiles/nvim/lua/plugins/lsp.lua`
- Consider working in subdirectories of large codebases
- Restart nvim periodically

## References

- Report Script: `~/dotfiles/scripts/nvim-process-report.sh`
- Cleanup Script: `~/dotfiles/scripts/cleanup-old-nvim.sh`
- Cleanup README: `~/dotfiles/scripts/cleanup-nvim-README.md`
- LaunchAgent: `~/dotfiles/launchd/com.user.cleanup-nvim.plist`
- Logs: `~/.local/log/cleanup-nvim.log`
