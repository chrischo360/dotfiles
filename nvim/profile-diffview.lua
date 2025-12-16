-- Diffview Performance Profiler
-- Usage: nvim -u profile-diffview.lua

-- Minimal init to isolate diffview
vim.cmd([[set runtimepath=$VIMRUNTIME]])
vim.cmd([[set packpath=/tmp/nvim/site]])

-- Bootstrap lazy.nvim for testing
local lazypath = "/tmp/nvim/site/pack/lazy/opt/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- Profile diffview in isolation
require("lazy").setup({
  {
    "nvim-lua/plenary.nvim",
  },
  {
    "sindrets/diffview.nvim",
    config = function()
      local start = vim.loop.hrtime()

      require("diffview").setup({
        enhanced_diff_hl = false,
        watch_index = false, -- Disable for profiling
      })

      local setup_time = (vim.loop.hrtime() - start) / 1e6
      print(string.format("Diffview setup: %.2fms", setup_time))
    end,
  },
})

-- Profile opening diffview
vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    vim.defer_fn(function()
      local start = vim.loop.hrtime()
      vim.cmd("DiffviewOpen")
      local open_time = (vim.loop.hrtime() - start) / 1e6
      print(string.format("DiffviewOpen command: %.2fms", open_time))
    end, 100)
  end,
})
