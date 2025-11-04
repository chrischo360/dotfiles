-- Plugin: Which-key
-- Description: Shows popup of available keybindings when you press <leader>. Helps you discover and remember shortcuts.
-- Keybindings: <leader>? (show buffer-local keymaps)

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

    -- Register LSP keybindings with organized groups
    wk.add({
      -- LSP Navigation (g-prefix)
      { "gd", desc = "LSP: Go to definition" },
      { "gD", desc = "LSP: Go to declaration" },
      { "gi", desc = "LSP: Go to implementation" },
      { "go", desc = "LSP: Go to type definition" },
      { "gr", desc = "LSP: Go to references" },
      { "gl", desc = "LSP: Open diagnostic float" },
      { "K", desc = "LSP: Hover documentation" },

      -- LSP Actions (leader-prefix)
      { "<leader>rn", desc = "LSP: Rename symbol" },
      { "<leader>ca", desc = "LSP: Code action" },
      { "<leader>f", desc = "LSP: Format buffer" },

      -- Diagnostic Navigation
      { "[d", desc = "Previous diagnostic" },
      { "]d", desc = "Next diagnostic" },

      -- Diagnostic Lists (x-prefix group)
      { "<leader>x", group = "🔧 Diagnostics" },
      { "<leader>xl", desc = "Set location list" },
      { "<leader>xq", desc = "Set quickfix list" },
    })

    -- Register DiffView keybindings with organized groups
    wk.add({
      { "<leader>d", group = "📊 DiffView" },
      { "<leader>dv", desc = "Toggle Diffview (uncommitted changes)" },
      { "<leader>dfh", desc = "File History (current file)" },
      { "<leader>dfa", desc = "File History (all files)" },
      { "<leader>dm", desc = "Compare with main/master" },
      { "<leader>db", desc = "Compare current with branch" },
      { "<leader>d2", desc = "Compare two branches" },
      { "<leader>dq", desc = "Quick Diff Menu" },
    })

    -- Register Harpoon keybindings with organized groups
    wk.add({
      { "<leader>h", group = "🎯 Harpoon" },
      { "<leader>ha", desc = "Add file" },
      { "<leader>hh", desc = "Toggle menu" },
      { "<leader>h1", desc = "Go to file 1" },
      { "<leader>h2", desc = "Go to file 2" },
      { "<leader>h3", desc = "Go to file 3" },
      { "<leader>h4", desc = "Go to file 4" },
      { "<leader>hn", desc = "Next file" },
      { "<leader>hp", desc = "Previous file" },
      { "<leader>hd", desc = "Remove file" },
      { "<leader>hc", desc = "Clear all" },
      { "<leader>ht", desc = "Telescope menu" },
      -- Alt-based navigation
      { "<M-h>", desc = "Harpoon: File 1" },
      { "<M-j>", desc = "Harpoon: File 2" },
      { "<M-k>", desc = "Harpoon: File 3" },
      { "<M-l>", desc = "Harpoon: File 4" },
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
