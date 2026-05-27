require("config.lazy")
require("config.notes")
require("config.git-keymaps")

-- Clear search highlighting with Escape
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>", { desc = "Clear search highlighting" })

-- Highlight the current line
vim.opt.cursorline = true

-- Indentation settings (2 spaces, no tabs)
vim.opt.tabstop = 2        -- Width of tab character
vim.opt.shiftwidth = 2     -- Indentation width for << and >>
vim.opt.softtabstop = 2    -- Number of spaces per Tab key press
vim.opt.expandtab = true   -- Use spaces instead of tabs

-- Mode-specific cursor shapes for better visual feedback
vim.opt.guicursor = {
  "n-v-c:block",           -- Normal, Visual, Command: block cursor
  "i-ci-ve:ver25",         -- Insert, Command Insert, Visual-Replace: thin vertical bar
  "r-cr:hor20",            -- Replace, Command Replace: horizontal bar
  "o:hor50",               -- Operator-pending: thick horizontal bar
  "a:blinkwait700-blinkoff400-blinkon250",  -- All modes: controlled blinking
  "sm:block-blinkwait175-blinkoff150-blinkon175",  -- Showmatch: fast blinking block
}

-- Override gx to handle URLs, markdown links, and relative paths
vim.keymap.set("n", "gx", function()
  -- Get current line and cursor position
  local line = vim.api.nvim_get_current_line()
  local col = vim.api.nvim_win_get_cursor(0)[2] + 1 -- Convert to 1-indexed

  -- Try to find markdown link [text](url) on current line
  -- Pattern captures the URL from markdown link syntax
  for text, url in line:gmatch("%[([^%]]+)%]%(([^%)]+)%)") do
    -- Calculate the position of this markdown link in the line
    local link_pattern = "%[" .. text:gsub("([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1") .. "%]%(" .. url:gsub("([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1") .. "%)"
    local start_pos, end_pos = line:find(link_pattern)

    -- Check if cursor is within this markdown link
    if start_pos and end_pos and col >= start_pos and col <= end_pos then
      -- Check if it's a URL or file path
      if url:match("^https?://") then
        vim.ui.open(url)
      else
        -- Handle as file path
        local path
        if url:match("^[~/]") then
          -- Absolute path
          path = vim.fn.resolve(vim.fn.expand(url))
        else
          -- Relative path from current buffer's directory
          local buf_dir = vim.fn.expand("%:p:h")
          path = vim.fn.resolve(buf_dir .. "/" .. url)
        end
        vim.cmd("edit " .. vim.fn.fnameescape(path))
      end
      return
    end
  end

  -- Fallback to original behavior: check word under cursor
  local word = vim.fn.expand("<cfile>")
  if word:match("^https?://") then
    vim.ui.open(word)
  else
    local path
    -- Check if path is absolute (starts with ~ or /)
    if word:match("^[~/]") then
      -- Expand ~ and resolve absolute path
      path = vim.fn.resolve(vim.fn.expand(word))
    else
      -- Relative path: resolve from current buffer's directory
      local buf_dir = vim.fn.expand("%:p:h")
      path = vim.fn.resolve(buf_dir .. "/" .. word)
    end
    vim.cmd("edit " .. vim.fn.fnameescape(path))
  end
end, { desc = "Open file/URL under cursor" })

-- Git performance profiling command
vim.api.nvim_create_user_command("ProfileGit", function()
  require("utils.profile-git").show_profile()
end, { desc = "Profile git and diffview performance" })
