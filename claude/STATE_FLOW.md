# Claude Session State Flow

Complete state tracking for tmux statusline display.

## States

### Status States
- **ACTIVE** - Claude is processing/responding
- **IDLE** - Claude finished, ready for user input
- **WAITING_FOR_INPUT** - Claude asked a question, needs user response

### Action Icons (shown during ACTIVE state)
- 📖 **Reading** = Read, Glob (finding/reading files)
- 🔍 **Searching** = Grep (searching code)
- ✏️ **Editing** = Edit, Write, NotebookEdit (modifying files)
- ⚙️ **Running** = Bash (executing commands)
- 🤖 **Delegating** = Task (spawning agents)
- 🌐 **Fetching** = WebFetch, WebSearch (web requests)
- 🔄 **Thinking** = Generic active (processing, no specific tool)
- ❓ **Question** = AskUserQuestion (asking user a question)
- ✅ **Ready** = Idle (finished, waiting for user input)

## Hook Execution Order

### Normal Response (No Question)

```
User submits input
    ↓
UserPromptSubmit → Set ACTIVE 🔄
    ↓
Claude thinks about response
    ↓
PreToolUse(Read) → Set ACTIVE 📖 (reading)
    ↓
Read executes
    ↓
PostToolUse(Read) → Set ACTIVE 🔄 (thinking)
    ↓
PreToolUse(Edit) → Set ACTIVE ✏️ (editing)
    ↓
Edit executes
    ↓
PostToolUse(Edit) → Set ACTIVE 🔄 (thinking)
    ↓
Stop → Set IDLE ✅
```

### Response with Question (AskUserQuestion)

```
User submits input
    ↓
UserPromptSubmit → Set ACTIVE 🔄
    ↓
Claude processes & decides to ask question
    ↓
PreToolUse(AskUserQuestion) → Set WAITING_FOR_INPUT ❓ (asking)
    ↓
AskUserQuestion executes (question shown)
    ↓
PostToolUse(AskUserQuestion) fires (if not interrupted)
    ↓
Stop → Check state:
    - If WAITING_FOR_INPUT → PRESERVE ❓
    - Otherwise → Set IDLE ✅
    ↓
User sees question, state remains: WAITING ❓
    ↓
User answers question
    ↓
UserPromptSubmit → Set ACTIVE 🔄
```

**Note:** Using PreToolUse ensures state is set to WAITING even if user interrupts/rejects the AskUserQuestion tool.

## Critical Timing

1. **PreToolUse fires BEFORE tool execution**
   - PreToolUse(AskUserQuestion) sets state to WAITING ⏳
   - Fires even if user interrupts/rejects the tool
   - More reliable than PostToolUse for state tracking

2. **PostToolUse fires AFTER successful tool execution**
   - Only fires if tool completes without interruption
   - Used as backup/confirmation for PreToolUse

3. **Stop hook fires AFTER all tool hooks**
   - Stop hook fires AFTER all PostToolUse hooks complete
   - Stop must preserve WAITING state (not override to IDLE)
   - Does NOT fire if user interrupts Claude mid-response (Ctrl+C)

4. **UserPromptSubmit always transitions to ACTIVE**
   - Whether answering a question or starting new conversation
   - Fires before Claude sees the input

## Hook Implementation

### SessionStart
- **When:** New session or resume
- **Action:** Set ACTIVE 🔄 (generic thinking)
- **File:** `claude/hooks/session/session-start.sh`

### UserPromptSubmit
- **When:** User submits any input
- **Action:** Set ACTIVE 🔄 (generic thinking)
- **File:** `claude/hooks/session/user-input.sh`

### PreToolUse
- **When:** Before ANY tool executes
- **Action:** Set ACTIVE with tool-specific action icon
- **File:** `claude/hooks/tools/pre-tool-use.sh`
- **Mapping:**
  - Read, Glob → 📖 reading
  - Grep → 🔍 searching
  - Edit, Write, NotebookEdit → ✏️ editing
  - Bash → ⚙️ running
  - Task → 🤖 delegating
  - WebFetch, WebSearch → 🌐 fetching
  - AskUserQuestion → ❓ waiting_for_input (special case)
  - Other tools → 🔄 generic active
- **Note:** Fires even if tool is interrupted/rejected

### PostToolUse
- **When:** After ANY tool executes successfully
- **Action:** Clear tool-specific action, back to ACTIVE 🔄 (thinking)
- **File:** `claude/hooks/tools/post-tool-use.sh`
- **Note:** AskUserQuestion skips this (already in waiting state)

### Stop
- **When:** Claude finishes responding (after all PostToolUse hooks)
- **Action:** Set IDLE ✅ (unless already WAITING ❓)
- **File:** `claude/hooks/session/claude-stop.sh`
- **Logic:**
  ```bash
  if current_status == "waiting_for_input"; then
    preserve waiting_for_input
  else
    set idle (clear action field)
  fi
  ```

### SessionEnd
- **When:** Session ends (cleanup)
- **Action:** Remove from state file
- **File:** `claude/hooks/session/session-end.sh`

## Edge Cases & Limitations

### User Interrupts Claude Mid-Response (Ctrl+C)
- **Limitation:** Stop hook does NOT fire on user interrupt
- **Result:** State remains ACTIVE ⚡ (stale)
- **Workaround:** None - this is a Claude Code limitation
- **Impact:** Statusline may show stale active state until next interaction

### User Interrupts/Rejects Tool Use
- **Scenario:** User rejects AskUserQuestion after seeing it
- **Behavior:** PreToolUse fires (sets WAITING ⏳), PostToolUse does NOT fire
- **Result:** State correctly shows WAITING ⏳
- **Fix:** Using PreToolUse instead of only PostToolUse handles this case

### Multiple Tools Including AskUserQuestion
- PostToolUse fires for each tool in sequence
- Last tool to fire determines state before Stop
- If AskUserQuestion is last, state will be WAITING ⏳
- Stop preserves the WAITING state

### Multiple Claude Sessions in Same tmux Session
- Each pane gets its own state entry
- Statusline shows all states: `main⚡⚡⏸️`
- Icons sorted by priority: ACTIVE > WAITING > IDLE

### Subagents (Task tool)
- Subagents have separate SubagentStop hook
- SubagentStop tracked separately (token tracking)
- Does NOT affect main session state

## State File Format

Location: `~/.claude/session-state.json`

```json
{
  "sessions": {
    "%1": {
      "status": "active",
      "action": "reading",
      "context": {
        "dir": "/path/to/project",
        "repo": "dotfiles",
        "branch": "main",
        "tmux_session": "main",
        "tmux_pane": "%1"
      },
      "last_update": "2025-12-21T12:34:56Z"
    },
    "%2": {
      "status": "waiting_for_input",
      "action": "asking",
      "context": {
        "dir": "/path/to/other",
        "repo": "work",
        "branch": "feature",
        "tmux_session": "work",
        "tmux_pane": "%2"
      },
      "last_update": "2025-12-21T12:35:00Z"
    },
    "%3": {
      "status": "idle",
      "context": {
        "dir": "/path/to/project",
        "repo": "dotfiles",
        "branch": "main",
        "tmux_session": "main",
        "tmux_pane": "%3"
      },
      "last_update": "2025-12-21T12:30:00Z"
    }
  }
}
```

**Notes:**
- `action` field is optional (only present when using specific tools)
- `action` is cleared when transitioning to `idle` or when tool completes
- Multiple sessions can exist in the same tmux session (different panes)

## Testing & Debugging

### View current state
```bash
~/dotfiles/claude/scripts/state/debug-status.sh
```

### Monitor hook execution
```bash
tail -f ~/.claude/hook-debug.log
```

### Manual state updates (testing)
```bash
~/dotfiles/claude/scripts/state/update-session-state.sh <action> [tool]
# Actions: start, active, idle, waiting, stop
# Tool: reading, searching, editing, running, delegating, fetching, asking
# Examples:
#   update-session-state.sh active reading    # Set to active+reading
#   update-session-state.sh active            # Set to active (generic)
#   update-session-state.sh idle              # Set to idle
#   update-session-state.sh waiting           # Set to waiting (asking)
```

### Verify hook timing
Send a message that uses AskUserQuestion and watch the log:
```
[12:34:56] UserPromptSubmit hook fired
[12:34:57] PostToolUse hook fired - tool: AskUserQuestion
[12:34:57] AskUserQuestion detected - setting state to waiting
[12:34:57] Stop hook fired
[12:34:57] Preserving waiting_for_input state
```

## Display Examples

| Scenario | Display |
|----------|---------|
| Claude reading files in "main" | `C: main📖` |
| Claude editing files in "main" | `C: main✏️` |
| Claude running bash in "work" | `C: work⚙️` |
| Claude asking question in "work" | `C: work❓` |
| Claude finished, idle in "dotfiles" | `C: dotfiles✅` |
| Multiple actions in "main" | `C: main📖✏️🔄` |
| Reading in "main", asking in "work" | `C: main📖 work❓` |
| Active in "main", idle in "dotfiles" | `C: main🔄 dotfiles✅` |
| 2 active (editing+searching), 1 idle | `C: main✏️🔍✅` |
