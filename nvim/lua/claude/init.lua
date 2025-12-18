local M = {}

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
  -- Get visual selection
  local selection = get_visual_selection()

  if not selection or selection == "" then
    vim.notify("No text selected", vim.log.levels.WARN)
    return
  end

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

    -- Create output window immediately
    local output_buf, output_win = create_float(" Claude Output ", 0.8, 0.8)
    vim.api.nvim_buf_set_option(output_buf, "modifiable", true)
    vim.api.nvim_buf_set_option(output_buf, "filetype", "markdown")

    -- Setup close keymaps
    setup_close_keymaps(output_buf)

    -- Start streaming
    run_claude(selection, prompt_text, output_buf, output_win, function(err)
      vim.schedule(function()
        if vim.api.nvim_win_is_valid(output_win) then
          vim.api.nvim_win_close(output_win, true)
        end
        show_error(err)
      end)
    end)
  end)

  -- Start insert mode
  vim.cmd("startinsert")
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
end

return M
