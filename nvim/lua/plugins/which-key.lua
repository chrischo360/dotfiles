return {
  "folke/which-key.nvim",
  event = "VeryLazy",
  config = function()
    local wk = require("which-key")
    
    -- Setup which-key
    wk.setup({
      -- your configuration comes here
      -- or leave it empty to use the default settings
    })
    
    -- Register Goose keybindings with organized groups
    wk.add({
      { "<leader>g", group = "🪿 Goose AI" },
      { "<leader>gm", group = "Mode" },
      { "<leader>gr", group = "Revert" },
    })
  end,
  keys = {
    {
      "<leader>?",
      function()
        require("which-key").show({ global = false })
      end,
      desc = "Buffer Local Keymaps (which-key)",
    },
  },
}
