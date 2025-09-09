-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

-- Make sure to setup `mapleader` and `maplocalleader` before
-- loading lazy.nvim so that mappings are correct.
-- This is also a good place to setup other settings (vim.opt)
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"
-- Line numbers configuration
vim.opt.number = true           -- Show absolute line numbers
vim.opt.relativenumber = true   -- Show relative line numbers
vim.opt.numberwidth = 4         -- Set the width of number column
vim.opt.signcolumn = "yes"      -- Always show sign column to prevent text shifting

-- Force line numbers to stay visible
vim.api.nvim_create_autocmd({"BufEnter", "WinEnter", "ColorScheme"}, {
  pattern = "*",
  callback = function()
    vim.wo.number = true
    vim.wo.relativenumber = true
  end,
})

-- Line number color overrides for transparency
vim.api.nvim_create_autocmd("ColorScheme", {
  pattern = "*",
  callback = function()
    -- Set visible line number colors that work with transparent backgrounds
    vim.api.nvim_set_hl(0, "LineNr", { 
      fg = "#6C7086",           -- Muted gray for relative line numbers
      bg = "NONE"               -- Transparent background
    })
    vim.api.nvim_set_hl(0, "CursorLineNr", { 
      fg = "#F38BA8",           -- Pink/red for current line number
      bg = "NONE",              -- Transparent background
      bold = true               -- Make current line bold
    })
    vim.api.nvim_set_hl(0, "SignColumn", {
      bg = "NONE"               -- Keep sign column transparent too
    })
  end,
})

-- Also set initial colors before any colorscheme loads
vim.api.nvim_set_hl(0, "LineNr", { fg = "#6C7086", bg = "NONE" })
vim.api.nvim_set_hl(0, "CursorLineNr", { fg = "#F38BA8", bg = "NONE", bold = true })
vim.api.nvim_set_hl(0, "SignColumn", { bg = "NONE" })
-- Light mode
vim.o.background = "light"
-- Enable clipboard integration
vim.opt.clipboard = "unnamedplus"

-- Search and navigation settings
vim.opt.scrolloff = 8           -- Keep 8 lines visible above/below cursor
vim.opt.hlsearch = true         -- Highlight all search matches
vim.opt.incsearch = true        -- Show matches as you type
vim.opt.ignorecase = true       -- Case insensitive search by default
vim.opt.smartcase = true        -- Case sensitive if uppercase letters used

-- Center screen on search navigation
vim.keymap.set('n', 'n', 'nzz', { desc = 'Next search result (centered)' })
vim.keymap.set('n', 'N', 'Nzz', { desc = 'Previous search result (centered)' })

-- Setup lazy.nvim
require("lazy").setup({
  spec = {
    -- import your plugins
    { import = "plugins" },
  },
  -- Configure any other settings here. See the documentation for more details.
  -- colorscheme that will be used when installing plugins.
  -- install = { colorscheme = { "habamax" } },
  -- automatically check for plugin updates
  checker = { enabled = false },
})

-- Setup local plugins after lazy.nvim
require("config.local-plugins")
