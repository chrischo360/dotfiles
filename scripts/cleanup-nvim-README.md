# Cleanup Old Nvim Instances

Automatically kills old or idle nvim instances and their LSP servers to free memory.

## Features

✅ **Kill by age** - Remove nvim instances older than specified hours (default: 48 hours/2 days)
✅ **Kill by idle status** - Remove instances that haven't been used (very low CPU time for their age)
✅ **Clean up LSP servers** - Automatically kills child processes (Intelephense, TypeScript LS, etc.)
✅ **Find orphans** - Detects and removes orphaned LSP servers whose parent nvim died
✅ **Dry run mode** - Test before actually killing processes
✅ **Automatic daily cleanup** - Optional LaunchAgent runs at 2 AM daily

## Usage

### Basic Usage

```bash
# Kill all nvim instances older than 48 hours (2 days) - default
~/dotfiles/scripts/cleanup-old-nvim.sh

# Kill all nvim instances older than 24 hours (1 day)
~/dotfiles/scripts/cleanup-old-nvim.sh 24

# Kill all nvim instances older than 72 hours (3 days)
~/dotfiles/scripts/cleanup-old-nvim.sh 72
```

### Dry Run (See What Would Be Killed)

```bash
# Dry run with default 48 hours
~/dotfiles/scripts/cleanup-old-nvim.sh --dry-run

# Dry run with custom hours
~/dotfiles/scripts/cleanup-old-nvim.sh 24 --dry-run
```

### Idle Detection Mode

```bash
# Kill only idle processes (48+ hours old with < 2 min CPU time)
~/dotfiles/scripts/cleanup-old-nvim.sh --idle-only --dry-run

# Actually kill idle processes
~/dotfiles/scripts/cleanup-old-nvim.sh --idle-only
```

### Combined Options

```bash
# Dry run for 12-hour-old processes
~/dotfiles/scripts/cleanup-old-nvim.sh 12 --dry-run

# Kill 36-hour-old processes (production)
~/dotfiles/scripts/cleanup-old-nvim.sh 36
```

## What Gets Killed

### Nvim Instances Killed When:
- **Age mode** (default): Older than specified hours (default: 48h)
- **Idle mode**: 48+ hours old AND less than 2 minutes total CPU time

### LSP Servers Killed:
- Child processes of killed nvim instances:
  - `intelephense` (PHP)
  - `typescript-language-server` (TypeScript/JavaScript)
  - `pyright` (Python)
  - `rust-analyzer` (Rust)
  - `lua-language-server` (Lua)

### Orphaned Servers:
- LSP servers whose parent nvim process no longer exists

## Example Output

```
🧹 Cleaning up nvim instances older than 48 hours...

📍 Found nvim instance to kill:
   PID: 12345
   Reason: age: 72h (idle)
   Age: 3d 72h
   CPU Time: 0:01.23
   Memory: 491 MB
   Started: Thu Dec 4 09:45:26 2025
   Child processes (LSP servers):
      - PID 12346: 3800 MB - node /Users/cc446g/.local/share/nvim/mason/bin/intelephense --stdio
   ✅ Killed child PID 12346
   ✅ Killed nvim PID 12345

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ Cleanup complete!
   Processes killed: 1
   Memory freed: ~4291 MB
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## Automatic Daily Cleanup

### Install LaunchAgent (runs at 2 AM daily)

```bash
# Create log directory
mkdir -p ~/.local/log

# Install the LaunchAgent
cp ~/dotfiles/launchd/com.user.cleanup-nvim.plist ~/Library/LaunchAgents/

# Load it (starts automatically)
launchctl load ~/Library/LaunchAgents/com.user.cleanup-nvim.plist

# Verify it's loaded
launchctl list | grep cleanup-nvim
```

### Uninstall Automatic Cleanup

```bash
# Unload the LaunchAgent
launchctl unload ~/Library/LaunchAgents/com.user.cleanup-nvim.plist

# Remove the plist
rm ~/Library/LaunchAgents/com.user.cleanup-nvim.plist
```

### Check Logs

```bash
# View cleanup log
tail -f ~/.local/log/cleanup-nvim.log

# View error log
tail -f ~/.local/log/cleanup-nvim-error.log
```

## Shell Aliases (Recommended)

Add to `~/.zshrc`:

```bash
# Nvim cleanup aliases
alias cleanup-nvim='~/dotfiles/scripts/cleanup-old-nvim.sh'
alias cleanup-nvim-dry='~/dotfiles/scripts/cleanup-old-nvim.sh --dry-run'
alias cleanup-nvim-idle='~/dotfiles/scripts/cleanup-old-nvim.sh --idle-only'
alias cleanup-nvim-now='~/dotfiles/scripts/cleanup-old-nvim.sh 0'  # Kill ALL nvim
```

Then use:
```bash
cleanup-nvim              # Kill 48h+ old instances
cleanup-nvim-dry          # Dry run for 48h+
cleanup-nvim-idle         # Kill only idle instances
cleanup-nvim 24           # Kill 24h+ old instances
cleanup-nvim-now          # Kill ALL nvim instances (careful!)
```

## When to Use

### Daily Automatic (Recommended)
- Install the LaunchAgent to run at 2 AM
- Kills processes older than 2 days automatically
- Frees 2-5 GB memory typically

### Manual Cleanup
```bash
# End of work day
cleanup-nvim 12           # Kill instances older than 12 hours

# Weekly cleanup
cleanup-nvim-idle         # Kill idle instances only

# Emergency - system running slow
cleanup-nvim 6            # Kill instances older than 6 hours
```

## Idle Detection Logic

A process is considered **idle** if:
- Age: 48+ hours old
- CPU Time: Less than 2 minutes total CPU time

**Example:**
- Process running for 3 days (72h) but only 90s CPU time = **IDLE** ✅
- Process running for 3 days (72h) with 15 min CPU time = **ACTIVE** ❌

## Expected Memory Savings

- **Old nvim instances**: 200-600 MB each
- **Intelephense (PHP LSP)**: 2-4 GB each
- **TypeScript LSP**: 50-200 MB each
- **Other LSPs**: 10-100 MB each

**Total:** Typically **2-5 GB freed** per cleanup

## Safety

- ✅ **Dry run first** - Always test with `--dry-run`
- ✅ **Graceful shutdown** - Sends SIGTERM first, then SIGKILL if needed
- ✅ **Age threshold** - Default 48 hours prevents killing active sessions
- ✅ **Idle detection** - Ensures truly unused processes
- ⚠️ **No auto-save** - Nvim instances are killed without saving

## Troubleshooting

### Script not working?
```bash
# Check if script is executable
ls -la ~/dotfiles/scripts/cleanup-old-nvim.sh

# Make it executable
chmod +x ~/dotfiles/scripts/cleanup-old-nvim.sh
```

### LaunchAgent not running?
```bash
# Check if loaded
launchctl list | grep cleanup-nvim

# View LaunchAgent logs
log show --predicate 'subsystem == "com.user.cleanup-nvim"' --last 1d
```

### No processes killed?
```bash
# Check current nvim ages
ps -eo pid,lstart,time,rss,command | grep "nvim --embed" | grep -v grep

# Lower the threshold
cleanup-old-nvim 24  # Try 24 hours instead of 48
```

## References

- Script: `~/dotfiles/scripts/cleanup-old-nvim.sh`
- LaunchAgent: `~/dotfiles/launchd/com.user.cleanup-nvim.plist`
- Logs: `~/.local/log/cleanup-nvim.log`
