-- Claude Code integration for Neovim
-- Allows sending visual selections to Claude Code CLI with streaming output

local M = {
  output_win = nil,
  output_buf = nil,
  original_win = nil,
  selection_marks = nil,
}

-- Configuration
local config = {
  border = "rounded",
}

-- Create a centered floating window
local function create_float(title, width_ratio, height_ratio)
  local width = math.floor(vim.o.columns * width_ratio)
  local height = math.floor(vim.o.lines * height_ratio)
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)

  local buf = vim.api.nvim_create_buf(false, true)
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    style = "minimal",
    border = config.border,
    title = title,
    title_pos = "center",
  })

  -- Set buffer options for easy closing
  vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")

  return buf, win
end

-- Create a floating window positioned below visual selection
local function create_float_below_selection(title, width_ratio, height_ratio, win_id)
  -- Get visual selection boundaries
  local start_pos = vim.fn.getpos("'<")
  local end_pos = vim.fn.getpos("'>")
  local end_line = end_pos[2]
  local end_col = end_pos[3]

  -- Calculate dimensions
  local width = math.floor(vim.o.columns * width_ratio)
  local height = math.floor(vim.o.lines * height_ratio)

  -- Get screen position of selection end using correct window
  local screen_pos = vim.fn.screenpos(win_id or 0, end_line, end_col)

  -- Position below selection
  local row = screen_pos.row
  local col = 0  -- Left-aligned
  local anchor = 'NW'  -- Northwest corner

  -- Handle bottom-of-screen case
  if row + height > vim.o.lines - 2 then
    -- Position above selection instead
    local start_screen = vim.fn.screenpos(0, start_pos[2], start_pos[3])
    row = start_screen.row - height - 1
    anchor = 'NW'

    -- If still doesn't fit, use centered fallback
    if row < 0 then
      row = math.floor((vim.o.lines - height) / 2)
      col = math.floor((vim.o.columns - width) / 2)
    end
  end

  -- Create buffer and window
  local buf = vim.api.nvim_create_buf(false, true)
  local win = vim.api.nvim_open_win(buf, true, {
    relative = 'editor',
    width = width,
    height = height,
    row = row,
    col = col,
    anchor = anchor,
    style = 'minimal',
    border = config.border,
    title = title,
    title_pos = 'center',
  })

  vim.api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')

  return buf, win
end

-- Helper to setup close keymaps for a buffer
local function setup_close_keymaps(buf)
  local close_keys = { "q", "<Esc>", "<C-c>" }
  for _, key in ipairs(close_keys) do
    vim.api.nvim_buf_set_keymap(buf, "n", key, ":close<CR>", {
      noremap = true,
      silent = true,
      nowait = true,
    })
  end
end

-- Get visual selection
local function get_visual_selection()
  local start_pos = vim.fn.getpos("'<")
  local end_pos = vim.fn.getpos("'>")
  local start_line = start_pos[2] - 1
  local end_line = end_pos[2]

  local lines = vim.api.nvim_buf_get_lines(0, start_line, end_line, false)
  return table.concat(lines, "\n")
end

-- Add session footer to buffer
local function add_session_footer(buf, session_id)
  local current_lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)

  table.insert(current_lines, "")
  table.insert(current_lines, string.rep("─", 80))
  table.insert(current_lines, "Session ID: " .. session_id)
  table.insert(current_lines, "Continue: claude --resume " .. session_id)

  vim.api.nvim_buf_set_option(buf, "modifiable", true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, current_lines)
  vim.api.nvim_buf_set_option(buf, "modifiable", false)
end

-- Run claude CLI command with streaming
local function run_claude(code, prompt, buf, win, on_error)
  local input = string.format("%s\n\n```\n%s\n```", prompt, code)

  -- Create temporary file for input to preserve formatting
  local tmpfile = os.tmpname()
  local f = io.open(tmpfile, "w")
  f:write(input)
  f:close()

  local cmd = string.format("cat '%s' | claude --print --verbose --output-format stream-json 2>&1", tmpfile)

  local current_text = ""
  local session_id = nil
  local all_output = {}  -- Capture all output for debugging

  vim.fn.jobstart(cmd, {
    on_stdout = function(_, data)
      if not data then return end

      vim.schedule(function()
        if not vim.api.nvim_win_is_valid(win) then return end

        -- Process each line as a JSON event
        for _, line in ipairs(data) do
          if line ~= "" then
            -- Store all output for error reporting
            table.insert(all_output, line)

            local ok, event = pcall(vim.json.decode, line)
            if ok then
              -- Handle system init event (has session ID)
              if event.type == "system" and event.subtype == "init" and event.session_id then
                session_id = event.session_id
              -- Handle assistant message (has the content)
              elseif event.type == "assistant" and event.message and event.message.content then
                for _, content_block in ipairs(event.message.content) do
                  if content_block.type == "text" and content_block.text then
                    current_text = current_text .. content_block.text

                    -- Update buffer with current text
                    local lines = vim.split(current_text, "\n")
                    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

                    -- Auto-scroll to bottom
                    local line_count = #lines
                    if line_count > 0 then
                      vim.api.nvim_win_set_cursor(win, {line_count, 0})
                    end
                  end
                end
              -- Handle result event (also has session ID)
              elseif event.type == "result" and event.session_id and not session_id then
                session_id = event.session_id
              end
            end
          end
        end
      end)
    end,
    on_exit = function(_, exit_code)
      vim.schedule(function()
        -- Clean up temp file
        os.remove(tmpfile)

        if not vim.api.nvim_win_is_valid(win) then return end

        if exit_code ~= 0 then
          local error_msg = table.concat(all_output, "\n")
          if error_msg == "" then
            error_msg = "Command failed with no output"
          end
          on_error("Exit code " .. exit_code .. ":\n\n" .. error_msg)
        else
          -- Make buffer read-only
          vim.api.nvim_buf_set_option(buf, "modifiable", false)
          -- Add session ID footer if available
          if session_id then
            add_session_footer(buf, session_id)
          end
        end
      end)
    end,
  })
end

-- Show error in floating window
local function show_error(error_msg)
  local buf, win = create_float(" Error ", 0.8, 0.6)

  local lines = {
    "",
    "  ✗ Error running Claude:",
    "",
  }

  -- Split error message by newlines and add each line
  for _, line in ipairs(vim.split(error_msg, "\n")) do
    table.insert(lines, "  " .. line)
  end

  table.insert(lines, "")

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(buf, "modifiable", false)

  -- Setup close keymaps
  setup_close_keymaps(buf)
end

-- Main function to invoke Claude
function M.invoke()
  -- Save original window
  M.original_win = vim.api.nvim_get_current_win()

  -- Get visual selection (this also saves the marks)
  local selection = get_visual_selection()

  if not selection or selection == "" then
    vim.notify("No text selected", vim.log.levels.WARN)
    return
  end

  -- Save selection marks for restoration
  M.selection_marks = {
    start = vim.fn.getpos("'<"),
    finish = vim.fn.getpos("'>"),
  }

  -- Create input prompt window
  local input_buf, input_win = create_float(" Enter Prompt ", 0.6, 0.2)

  -- Enable insert mode and prompt for input
  vim.api.nvim_buf_set_option(input_buf, "buftype", "prompt")
  vim.fn.prompt_setprompt(input_buf, "❯ ")

  -- Add keymaps to close input window
  vim.api.nvim_buf_set_keymap(input_buf, "n", "<Esc>", ":close<CR>", {
    noremap = true,
    silent = true,
  })
  vim.api.nvim_buf_set_keymap(input_buf, "n", "q", ":close<CR>", {
    noremap = true,
    silent = true,
  })

  -- Handle prompt submission
  vim.fn.prompt_setcallback(input_buf, function(prompt_text)
    -- Close input window
    vim.api.nvim_win_close(input_win, true)

    if not prompt_text or prompt_text == "" then
      vim.notify("No prompt entered", vim.log.levels.WARN)
      return
    end

    -- Create output window using new positioning function
    M.output_buf, M.output_win = create_float_below_selection(" Claude Output ", 0.8, 0.8, M.original_win)
    vim.api.nvim_buf_set_option(M.output_buf, "modifiable", true)
    vim.api.nvim_buf_set_option(M.output_buf, "filetype", "markdown")

    -- Setup close keymaps
    setup_close_keymaps(M.output_buf)

    -- RESTORE VISUAL SELECTION
    -- Stay in original window with selection highlighted
    vim.schedule(function()
      if M.original_win and vim.api.nvim_win_is_valid(M.original_win) then
        vim.api.nvim_set_current_win(M.original_win)
        vim.cmd('normal! gv')
      end
    end)

    -- Start streaming
    run_claude(selection, prompt_text, M.output_buf, M.output_win, function(err)
      vim.schedule(function()
        if M.output_win and vim.api.nvim_win_is_valid(M.output_win) then
          vim.api.nvim_win_close(M.output_win, true)
        end
        show_error(err)
      end)
    end)
  end)

  -- Start insert mode
  vim.cmd("startinsert")
end

-- Toggle Claude output window visibility
function M.toggle_output()
  if M.output_win and vim.api.nvim_win_is_valid(M.output_win) then
    -- Hide window
    vim.api.nvim_win_hide(M.output_win)
    M.output_win = nil
  else
    -- Show window again if buffer exists
    if M.output_buf and vim.api.nvim_buf_is_valid(M.output_buf) then
      -- Recreate window at centered position
      local width = math.floor(vim.o.columns * 0.8)
      local height = math.floor(vim.o.lines * 0.8)
      M.output_win = vim.api.nvim_open_win(M.output_buf, true, {
        relative = 'editor',
        width = width,
        height = height,
        row = math.floor((vim.o.lines - height) / 2),
        col = math.floor((vim.o.columns - width) / 2),
        style = 'minimal',
        border = config.border,
        title = ' Claude Output ',
        title_pos = 'center',
      })
      setup_close_keymaps(M.output_buf)
    end
  end

  -- Restore visual selection if we have marks
  if M.original_win and vim.api.nvim_win_is_valid(M.original_win) and M.selection_marks then
    local current_win = vim.api.nvim_get_current_win()
    vim.api.nvim_set_current_win(M.original_win)
    vim.cmd('normal! gv')
    if M.output_win then
      vim.api.nvim_set_current_win(M.output_win)
    else
      vim.api.nvim_set_current_win(current_win)
    end
  end
end

-- Setup function
function M.setup(opts)
  config = vim.tbl_deep_extend("force", config, opts or {})

  -- Create :Claude command (visual mode only)
  vim.api.nvim_create_user_command("Claude", function()
    M.invoke()
  end, {
    range = true,
    desc = "Send visual selection to Claude Code",
  })

  -- Add toggle keybinding
  vim.keymap.set("n", "<leader>ct", function()
    M.toggle_output()
  end, { desc = "Toggle Claude output window" })
end

-- Return lazy.nvim plugin spec
return {
  name = "claude-nvim",
  dir = vim.fn.stdpath("config") .. "/lua/plugins",
  config = function()
    M.setup()
  end,
  keys = {
    {
      "<leader>c",
      ":Claude<CR>",
      mode = "v",
      desc = "Send to Claude Code",
    },
  },
}
