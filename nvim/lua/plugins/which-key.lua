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
      { "<leader>gn", group = "Notifications" },
      { "<leader>gnt", "<cmd>GooseToggleNotifications<cr>", desc = "Toggle Notifications" },
      { "<leader>gnc", "<cmd>GooseConfigureNotifications<cr>", desc = "Configure Notifications" },
      { "<leader>gns", "<cmd>GooseTestNotification<cr>", desc = "Test Notification" },
      { "<leader>gnd", "<cmd>GooseDebugNotifications<cr>", desc = "Debug Notifications" },
    })

    -- Register Claude keybindings with organized groups
    wk.add({
      { "<leader>c", group = "🤖 Claude AI" },
      -- The new keymap for claude-code.nvim
      { "<leader>cc", "<cmd>ClaudeCode<CR>", desc = "Toggle Claude Code" },
      { "<leader>cr", group = "Refactor" },
      { "<leader>cm", group = "Model" },
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
