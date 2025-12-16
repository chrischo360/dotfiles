
 Shell Startup Slowness - System Resource Issue

 Problem Statement

 - Shell startup degrades to ~2 seconds after running npm commands in large repos
 - Returns to normal after PC restart
 - NOT a zsh configuration issue - it's system resource exhaustion

 Root Cause (CONFIRMED)

 SWAP THRASHING - The real culprit:
 - Physical RAM: 22GB/24GB used (92% full)
 - Swap usage: 6.2GB/7.2GB used (87% full)
 - Diagnosis: System is heavily swapping to disk
 - Effect: Every file I/O hits slow disk instead of fast RAM (1000x slower)

 Working in large npm repos causes memory accumulation:
 1. Node/npm processes holding memory (not zombie, just memory-heavy)
 2. File system cache growing from npm's massive file I/O
 3. Compressor memory (1.8GB) from memory pressure
 4. No free RAM forces everything to swap

 Current Performance (When Degraded)

 - FZF initialization: 319ms (subprocess spawn)
 - Every file source: 150-300ms (should be <10ms)
 - Total: ~2.1 seconds

 Diagnosis Results

 # Node processes: 7 (NORMAL - not the issue)
 ps aux | grep node | wc -l  # → 7

 # Open files: 14,374 (NORMAL - within limits)
 lsof | wc -l               # → 14,374
 ulimit -n                  # → 2,560 per process

 # Memory: 22GB/24GB used (CRITICAL - 92% full)
 PhysMem: 22G used (3028M wired, 1841M compressor), 1774M unused

 # Swap: 6.2GB/7.2GB used (CRITICAL - heavy swap thrashing)
 vm.swapusage: total = 7168.00M  used = 6229.44M  free = 938.56M

 Root cause confirmed: SWAP THRASHING from memory exhaustion.

 Solutions

 Immediate Relief (Free Memory Now)

 1. Add memory cleanup commands

 File: zsh/custom/05-aliases.zsh

 # Check current memory/swap status
 alias memstat='echo "=== Memory ===" && top -l 1 | grep PhysMem && echo "=== Swap
 ===" && sysctl vm.swapusage'

 # Purge disk cache and inactive memory (requires sudo)
 alias purge-mem='sudo purge && echo "Memory caches purged"'

 # Kill memory-heavy processes
 alias cleanup-mem='echo "Top memory consumers:" && ps aux | sort -k4 -r | head -10'

 # Full cleanup after npm work
 alias cleanup-npm='echo "Killing node processes..." && pkill node 2>/dev/null; echo
  "Purging memory..." && sudo purge && memstat'

 2. Add memory pressure warning on shell startup

 File: zsh/custom/05-aliases.zsh

 # Warn if swap usage is high (slow shell startup indicator)
 _check_memory_pressure() {
   local swap_used=$(sysctl vm.swapusage | grep -o 'used = [0-9.]*' | awk '{print
 $3}' | cut -d. -f1)
   if [[ $swap_used -gt 4000 ]]; then
     echo "⚠️  WARNING: ${swap_used}MB swap in use - shell will be slow!"
     echo "   Run 'cleanup-npm' or restart to clear memory"
   fi
 }
 _check_memory_pressure

 Long-term Optimizations (Still Worth Doing)

 1. Cache FZF initialization (saves 319ms always)

 File: zsh/custom/09-fzf.zsh

 # Cache fzf --zsh output
 FZF_CACHE=~/.cache/fzf-init.zsh
 mkdir -p ~/.cache

 if [[ ! -f $FZF_CACHE ]] || [[ /opt/homebrew/opt/fzf/bin/fzf -nt $FZF_CACHE ]];
 then
   fzf --zsh > $FZF_CACHE
 fi

 [ -f $FZF_CACHE ] && source $FZF_CACHE

 # FZF options (keep existing)
 export FZF_DEFAULT_OPTS="--height 40% --layout=reverse --border"
 if command -v fd &> /dev/null; then
   export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
   export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
 fi

 2. Remove NVM file I/O

 File: zsh/custom/02-paths.zsh

 Replace NVM detection (lines 6-19) with hardcoded version:
 # Use fnm's node (already lazy-loaded) or hardcode version
 export PATH="$HOME/.local/share/fnm/node-versions/v22.18.0/bin:$PATH"

 Implementation Order

 1. Add memory monitoring/cleanup commands (diagnose and fix in real-time)
 2. Add swap usage warning (alerts when slowness will occur)
 3. Cache FZF (reduces I/O when swapping)
 4. Remove timing instrumentation from .zshrc
 5. Long-term: Identify memory-heavy processes or add more RAM

 Expected Results

 - When system healthy (no swap): ~100-200ms startup
 - When swapping (before fix): ~2 seconds, no warning
 - When swapping (after fix): ~2 seconds, but WITH warning + cleanup commands
 - After running cleanup-npm: Back to ~100-200ms without restart
 - Long-term: User awareness of memory pressure, can proactively manage it

 Files to Modify

 1. ~/dotfiles/zsh/custom/05-aliases.zsh - Add cleanup commands and warning
 2. ~/dotfiles/zsh/.zshrc - Add zshexit hook, remove timing code
 3. ~/dotfiles/zsh/custom/09-fzf.zsh - Cache fzf initialization
 4. ~/dotfiles/zsh/custom/02-paths.zsh - (Optional) Remove NVM file I/O
