# Claude Code - Future Enhancements

This document captures planned features and enhancements that are not part of the initial implementation but should be considered for future development.

---

## 1. Agent Persona Workflow (Multi-Phase AI System)

### Overview
A sophisticated multi-agent system to handle complex development tasks using a hybrid approach with `goose.nvim` (for research) and `claude-code.nvim` (for coding).

### Implementation Plan

#### Phase 1: Discovery (Parallel Tasks)

**1. Requirements Gathering Agent**
- **Purpose**: Interact with the user to define scope and requirements.
- **Tool**: `goose.nvim`
- **Model**: Gemini 2.5 Pro (large context window)
- **Extensions**: Glean, Atlassian, GitHub, Context7
- **Mode**: Plan Mode
- **Output**: `requirements.md`

**2. Technical Research Agent**
- **Purpose**: Gather technical context and identify relevant assets.
- **Tool**: `goose.nvim`
- **Model**: Gemini 2.5 Pro
- **Extensions**: Glean, Atlassian, GitHub, Context7
- **Mode**: Plan Mode
- **Responsibilities**:
  - Identify relevant code repositories and files
  - Find key individuals who worked on related code
  - Surface related PRs, design docs, Slack threads
- **Output**: `research.md`

#### Phase 2: Planning

**3. Implementation Planner Agent**
- **Purpose**: Synthesize requirements and research into implementation strategy.
- **Tool**: `claude-code.nvim`
- **Model**: Claude Opus (strong reasoning)
- **Extensions**: Memory
- **Mode**: Plan Mode
- **Input**: `requirements.md` + `research.md`
- **Output**: `implementation_plan.md`

#### Phase 3: Execution & Verification

**4. Task Coordinator & QA Agent**
- **Purpose**: Manage execution and ensure quality.
- **Tool**: `claude-code.nvim`
- **Model**: Claude Opus/Sonnet
- **Extensions**: Memory
- **Mode**: Act Mode
- **Input**: `implementation_plan.md`
- **Responsibilities**:
  - Break down plan into discrete sub-tasks
  - Define verification methods (reasoning reports, unit tests)
  - Oversee work of other agents
  - Verify correctness and catch hallucinations

### Technical Implementation

**File Structure**:
```
lua/
├── core/
│   └── agents.lua          # Agent persona definitions
├── plugins/
│   ├── claude.lua          # Claude code configuration
│   └── goose.lua           # Goose configuration
```

**Agent Definition Schema** (`agents.lua`):
```lua
local agents = {
  requirements_gathering = {
    name = "Requirements Gathering Agent",
    tool = "goose",
    model = "gemini-2.5-pro",
    extensions = { "glean", "github", "context7" },
    mode = "plan",
    prompt = [[
      You are a Requirements Gathering Agent.
      Your purpose is to interact with the user to define
      the scope and requirements of a feature or task.
      
      Steps:
      1. Ask relevant questions about the feature/task/goals
      2. Organize information into a formal requirements document
      3. Save output as requirements.md
    ]],
  },
  
  technical_research = {
    name = "Technical Research Agent",
    tool = "goose",
    model = "gemini-2.5-pro",
    extensions = { "glean", "github", "context7" },
    mode = "plan",
    prompt = [[
      You are a Technical Research Agent.
      Your purpose is to gather technical context and identify
      relevant assets and personnel.
      
      Steps:
      1. Identify relevant code repositories and files
      2. Find key individuals who worked on related code
      3. Surface related PRs, design docs, Slack threads
      4. Save output as research.md
    ]],
  },
  
  implementation_planner = {
    name = "Implementation Planner Agent",
    tool = "claude",
    model = "claude-opus-4-1@20250805",
    extensions = { "memory" },
    mode = "plan",
    prompt = [[
      You are an Implementation Planner Agent.
      Your purpose is to synthesize requirements and research
      into a coherent implementation strategy.
      
      Input files: requirements.md, research.md
      
      Steps:
      1. Read and understand the provided documentation
      2. Create a detailed implementation_plan.md
      3. Outline the proposed solution with clear steps
    ]],
  },
  
  task_coordinator = {
    name = "Task Coordinator & QA Agent",
    tool = "claude",
    model = "claude-opus-4-1@20250805",
    extensions = { "memory" },
    mode = "act",
    prompt = [[
      You are a Task Coordinator & QA Agent.
      Your purpose is to manage execution and ensure quality.
      
      Input file: implementation_plan.md
      
      Steps:
      1. Break down the high-level plan into smaller sub-tasks
      2. Define verification methods for each sub-task
      3. Oversee work of other agents
      4. Verify completed work is correct and error-free
    ]],
  },
}

return agents
```

**Keybinding**:
- `<leader>cA` - Open agent persona picker (Telescope)

**Telescope Picker Implementation**:
```lua
local function select_agent_persona()
  local agents = require('core.agents')
  local pickers = require('telescope.pickers')
  local finders = require('telescope.finders')
  local conf = require('telescope.config').values
  local actions = require('telescope.actions')
  local action_state = require('telescope.actions.state')
  
  pickers.new({}, {
    prompt_title = "Select Agent Persona",
    finder = finders.new_table {
      results = agents,
      entry_maker = function(entry)
        return {
          value = entry,
          display = entry.name,
          ordinal = entry.name,
        }
      end,
    },
    sorter = conf.generic_sorter({}),
    attach_mappings = function(prompt_bufnr, map)
      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        local agent = selection.value
        
        -- Activate the appropriate tool with the agent's prompt
        if agent.tool == "goose" then
          -- Use goose.nvim
          require('goose.api').run_new_session(agent.prompt)
        elseif agent.tool == "claude" then
          -- Use claude-code.nvim
          vim.cmd('ClaudeChat')
          -- Inject the agent prompt (implementation depends on plugin API)
        end
      end)
      return true
    end,
  }):find()
end

vim.keymap.set('n', '<leader>cA', select_agent_persona, 
  { desc = "Select Agent Persona" })
```

---

## 2. Advanced Session Management

### Description
If `claude-code.nvim` adds more sophisticated session/window management in the future (similar to `goose.nvim`), we can implement these keybindings:

**Keybindings to Add**:
- `<leader>cs` - Select Claude session (from history)
- `<leader>ct` - Toggle focus between Claude windows
- `<leader>co` - Open Claude output window
- `<leader>cq` - Close all Claude windows

**Implementation Notes**:
- These commands would require the plugin to support:
  - Multiple named sessions
  - Dedicated input/output buffer management
  - Session persistence and recall
  - Window focus toggling

**Current Workaround**:
- Use standard Vim window commands:
  - `<C-w>w` - Cycle through windows
  - `<C-w>h/j/k/l` - Move to specific window
  - `<C-w>q` - Close current window

---

## 3. Notification System (Like Goose)

### Description
Add a completion notification system similar to the one implemented in `goose.nvim`.

**Features**:
- Visual notifications when Claude completes a task
- System sounds
- Duration tracking
- Session name display
- Repository/branch context
- Toggle and configuration commands

**Keybindings**:
- `<leader>cn` group for notifications
- `<leader>cnt` - Toggle notifications
- `<leader>cnc` - Configure notifications
- `<leader>cns` - Test notification

**Implementation Reference**: See `goose.lua` notification system (lines ~100-300)

---

## 4. Context7 Integration for Documentation

### Description
Enhance code generation by automatically fetching relevant library documentation using the Context7 extension.

**Use Case**: When generating code that uses a specific library (e.g., React, FastAPI), automatically fetch and inject the latest documentation into the context.

**Implementation**:
- Hook into the `ClaudeGenerate` command
- Parse user prompt for library names
- Fetch documentation via `context7__get-library-docs`
- Inject into Claude's context before generation

---

## 5. Plan Mode Default Setting

### Description
You mentioned wanting "Plan Mode" as the default. This may be a setting within `claude-code.nvim` itself.

**Action Items**:
1. Review the plugin's configuration options for a `mode` or `plan_mode` setting
2. If available, add to the `setup()` configuration in `claude.lua`
3. If not available, consider creating a custom prompt prefix that instructs Claude to "always create a plan first"

**Example Custom Prompt Prefix**:
```lua
http_options = {
  -- ... existing config ...
  system_prompt_prefix = [[
    Before responding to any request, first create a detailed plan
    outlining the steps you will take. Then execute the plan.
  ]],
}
```

---

## Implementation Priority

1. **High Priority**: Agent Persona Workflow (most impactful for your multi-phase development process)
2. **Medium Priority**: Notification System (quality of life improvement)
3. **Low Priority**: Advanced Session Management (wait for plugin to add features)
4. **Research**: Plan Mode Default (verify if plugin supports this)
5. **Future**: Context7 Integration (nice-to-have enhancement)

---

## Notes

- Keep this document updated as new features are discovered or requested
- When implementing, create new files/modules rather than cluttering `claude.lua`
- Use feature flags or configuration options to enable/disable experimental features
- Test each enhancement independently before combining them
