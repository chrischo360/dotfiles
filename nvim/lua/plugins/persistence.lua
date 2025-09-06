return {
  'folke/persistence.nvim',
  event = "BufReadPre",
  keys = {
    { "<leader>ql", function() require("persistence").load() end, desc = "Load Last Session" },
    { "<leader>qs", function() require("persistence").save() end, desc = "Save Current Session" },
    { "<leader>qd", function() require("persistence").stop() end, desc = "Don't Save Current Session" },
  },
  config = function()
    require("persistence").setup({
      dir = vim.fn.expand(vim.fn.stdpath("state") .. "/sessions/"),
      options = { "buffers", "curdir", "tabpages", "winsize", "help", "globals" },
      pre_save = function() vim.cmd("NeoTreeClose") end,
      save_empty = false,
    })
  end
}
