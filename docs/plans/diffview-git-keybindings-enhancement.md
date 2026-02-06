# Diffview Git Keybindings Enhancement

## Overview
Add two features to diffview.nvim configuration:
1. **`gc` keybinding** - Commit staged files with message prompt
2. **`g?g` keybinding** - Toggle git-specific help panel (hideable)

## Current State

### Keymap Architecture (nvim/lua/plugins/diffview.lua)

Keymaps organized in 7 sections (lines 196-327):
- `view` - Active diff window
- `diff1/2/3/4` - Diff mode variants
- `file_panel` - File list sidebar (main git operations location)
- `file_history_panel` - Commit history
- `option_panel`, `help_panel` - UI controls

### Existing Git Operations
**file_panel section (lines 230-285):**
- `a` (line 242-268) - Stage/unstage file (with error logging)
- `U` (line 271) - Unstage all changes
- `R` (line 276) - Refresh view

**file_history_panel section (lines 286-318):**
- `y` (line 301) - Copy commit hash
- `L` (line 302) - Commit details

### Custom Action Pattern
See `goto_file_and_close()` (lines 63-91) for reference:
```lua
local function custom_action()
  local lib = require("diffview.lib")
  local view = lib.get_current_view()
  -- Action logic
end
```

## Implementation Plan

### 1. Add Commit Function (After line 91)

**Location:** Right after `goto_file_and_close()` function definition

**Code:**
```lua
-- Custom action: Commit staged files with message
local function commit_staged()
  local msg = vim.fn.input("Commit message: ")
  if msg and msg ~= "" then
    local result = vim.fn.system("git commit -m " .. vim.fn.shellescape(msg))
    if vim.v.shell_error == 0 then
      vim.notify("Committed: " .. msg, vim.log.levels.INFO)
      vim.cmd("DiffviewRefresh")
    else
      vim.notify("Commit failed: " .. result, vim.log.levels.ERROR)
    end
  end
end
```

**Why this approach:**
- User chose "Commit all staged files" option
- Uses `git commit -m` directly (simple, reliable)
- Refreshes diffview after successful commit
- Handles empty message gracefully

### 2. Create Centralized Keymap File

**Location:** Create new file `nvim/lua/utils/diffview-keymaps.lua`

**Rationale:**
- Follows existing pattern (`utils/diff-utils.lua` already exists)
- Single source of truth for keybindings
- Can be imported by both plugin config AND help panel
- Easier to maintain and update

**Code:**
```lua
-- /Users/cc446g/dotfiles/nvim/lua/utils/diffview-keymaps.lua
local M = {}

-- Git-focused keymaps for help panel
-- Organized by category with descriptions
M.help_categories = {
  {
    name = "Staging",
    keys = {
      { key = "a", desc = "Stage/unstage file" },
      { key = "U", desc = "Unstage all changes" },
      { key = "gc", desc = "Commit staged files" },
    },
  },
  {
    name = "Navigation",
    keys = {
      { key = "j/k", desc = "Next/previous file" },
      { key = "<Tab>", desc = "Next file (open)" },
      { key = "<S-Tab>", desc = "Previous file (open)" },
      { key = "<CR>", desc = "Open diff" },
    },
  },
  {
    name = "File Operations",
    keys = {
      { key = "gf", desc = "Go to file and close" },
      { key = "R", desc = "Refresh view" },
    },
  },
  {
    name = "View Controls",
    keys = {
      { key = "<leader>b", desc = "Toggle file panel" },
      { key = "i", desc = "Toggle list/tree" },
      { key = "g<C-x>", desc = "Cycle layout" },
    },
  },
  {
    name = "Help",
    keys = {
      { key = "g?", desc = "Full help" },
      { key = "g?g", desc = "Toggle this panel" },
    },
  },
}

-- Generate help text from categories
function M.generate_help_text()
  local lines = {
    "Git Keybindings",
    "================",
    "",
  }

  for _, category in ipairs(M.help_categories) do
    table.insert(lines, category.name .. ":")
    for _, keymap in ipairs(category.keys) do
      table.insert(lines, string.format("  %-12s - %s", keymap.key, keymap.desc))
    end
    table.insert(lines, "")
  end

  table.insert(lines, "Press q or <Esc> to close")
  return lines
end

return M
```

### 3. Add Git Help Panel Toggle (After commit function)

**Location:** After `commit_staged()` function in diffview.lua

**Code:**
```lua
-- Custom action: Toggle git keybindings help panel
local git_help_visible = false
local git_help_winid = nil

local function toggle_git_help()
  -- Close if already open
  if git_help_visible and git_help_winid and vim.api.nvim_win_is_valid(git_help_winid) then
    vim.api.nvim_win_close(git_help_winid, true)
    git_help_visible = false
    git_help_winid = nil
    return
  end

  -- Load help text from centralized keymap file
  local diffview_keymaps = require("utils.diffview-keymaps")
  local help_text = diffview_keymaps.generate_help_text()

  -- Create floating window
  local width = 50
  local height = #help_text
  local bufnr = vim.api.nvim_create_buf(false, true)

  local win_opts = {
    relative = "editor",
    width = width,
    height = height,
    row = math.floor((vim.o.lines - height) / 2),
    col = math.floor((vim.o.columns - width) / 2),
    style = "minimal",
    border = "rounded",
    title = " Git Help ",
    title_pos = "center",
  }

  local winid = vim.api.nvim_open_win(bufnr, true, win_opts)

  -- Set buffer content
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, help_text)

  -- Set buffer options
  vim.api.nvim_set_option_value("modifiable", false, { buf = bufnr })
  vim.api.nvim_set_option_value("bufhidden", "wipe", { buf = bufnr })

  -- Close on q or <Esc>
  vim.keymap.set("n", "q", function()
    vim.api.nvim_win_close(winid, true)
    git_help_visible = false
  end, { buffer = bufnr, nowait = true })

  vim.keymap.set("n", "<Esc>", function()
    vim.api.nvim_win_close(winid, true)
    git_help_visible = false
  end, { buffer = bufnr, nowait = true })

  git_help_visible = true
  git_help_winid = winid
end
```

**Why centralized approach:**
- Single source of truth for keybindings
- Easy to update when adding new keybindings
- Follows existing pattern in `utils/diff-utils.lua`
- Can be imported by other files if needed (e.g., which-key)

### 4. Add `gc` Keybinding to file_panel

**Location:** file_panel section, after line 271 (after `U` unstage keybinding)

**Add:**
```lua
{ "n", "gc", commit_staged, { desc = "Commit staged files" } },
```

**Reasoning:**
- Placed near other git staging operations (`a`, `U`)
- Uses mnemonic "git commit"
- User selected `gc` as preferred keybinding

### 5. Add `g?g` Keybinding to Multiple Sections

**Locations to add:**
1. **view section** (after line 208, after `g?` help)
2. **file_panel section** (after line 280, after `g?` help)
3. **file_history_panel section** (after line 312, after `g?` help)

**Add to each:**
```lua
{ "n", "g?g", toggle_git_help, { desc = "Git keybindings help" } },
```

**Why multiple sections:**
- User can access git help from any diffview context
- Follows pattern of `g?` (available in all sections)
- `g?g` mnemonic: "help (g?) for git (g)"

## Files to Modify

1. **nvim/lua/utils/diffview-keymaps.lua** - NEW FILE
   - Centralized keymap definitions for help panel
   - Follows existing pattern from `utils/diff-utils.lua`

2. **nvim/lua/plugins/diffview.lua** - Main diffview configuration
   - Lines 92-110: Add `commit_staged()` function
   - Lines 111-220: Add `toggle_git_help()` function (imports from utils/diffview-keymaps.lua)
   - Line 272: Add `gc` keybinding to file_panel
   - Lines 209, 281, 313: Add `g?g` keybinding to view/file_panel/file_history_panel

## Testing Plan

1. **Commit functionality:**
   - Stage files with `a`
   - Press `gc`, verify input prompt appears
   - Enter message, verify commit succeeds
   - Check diffview refreshes automatically

2. **Help panel:**
   - Press `g?g` in any diffview context
   - Verify floating window appears with git keybindings
   - Press `g?g` again, verify it closes (toggle behavior)
   - Press `q` or `<Esc>`, verify it closes
   - Verify content matches actual keybindings

3. **Edge cases:**
   - Empty commit message → should cancel gracefully
   - No staged files → git will show error, notify user
   - Help panel + navigation → verify no conflicts

## Design Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Commit scope | All staged files | User preference |
| Commit key | `gc` | User preference, mnemonic "git commit" |
| Help content | Centralized keymap file | Single source of truth, easier to maintain |
| Keymap file location | `utils/diffview-keymaps.lua` | Follows existing pattern from `utils/diff-utils.lua` |
| Help toggle | `g?g` | Mnemonic "help for git", consistent with `g?` |
| Help location | view/file_panel/file_history_panel | Accessible from any git context |
| Window style | Floating with border | Consistent with modern vim UI patterns |

## Implementation Notes

- Follow existing custom action pattern (see `goto_file_and_close`)
- Use `vim.notify()` for user feedback (matches existing error handling)
- Help panel uses state tracking (`git_help_visible`, `git_help_winid`) for toggle behavior
- `shellescape()` prevents command injection in commit messages
- `DiffviewRefresh` updates view after commit (similar to how `R` works)
