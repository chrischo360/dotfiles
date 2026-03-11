require("config.lazy")
require("config.notes")

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

-- Override gx to resolve relative paths from current buffer's directory
vim.keymap.set("n", "gx", function()
  local word = vim.fn.expand("<cfile>")
  if word:match("^https?://") then
    vim.ui.open(word)
  else
    local buf_dir = vim.fn.expand("%:p:h")
    local abs = vim.fn.resolve(buf_dir .. "/" .. word)
    vim.cmd("edit " .. vim.fn.fnameescape(abs))
  end
end, { desc = "Open file/URL under cursor" })

-- Git performance profiling command
vim.api.nvim_create_user_command("ProfileGit", function()
  require("utils.profile-git").show_profile()
end, { desc = "Profile git and diffview performance" })
