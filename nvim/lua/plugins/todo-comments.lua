-- Plugin: todo-comments.nvim
-- Description: Highlight and search for TODO, FIXME, NOTE, and WARN comments in your code
--
-- How it works:
--   - Scans code for comment patterns like "// TODO:", "# FIXME:", etc.
--   - Highlights them with colors (TODO=blue, FIXME=red, NOTE=teal, WARN=orange)
--   - Only works in CODE COMMENTS, not markdown text
--
-- Keybindings:
--   <leader>td - Open telescope with all TODOs
--   ]t - Jump to next TODO comment
--   [t - Jump to previous TODO comment

return {
  "folke/todo-comments.nvim",
  dependencies = { "nvim-lua/plenary.nvim" },
  event = "VeryLazy", -- Load on startup so highlights appear immediately
  config = function()
    require("todo-comments").setup({
      keywords = {
        TODO = { icon = " ", color = "info" },
        FIXME = { icon = " ", color = "error" },
        NOTE = { icon = " ", color = "hint" },
        WARN = { icon = " ", color = "warning" },
      },
      highlight = {
        before = "",
        keyword = "wide",
        after = "fg",
      },
    })
  end,
  keys = {
    { "<leader>td", "<cmd>TodoTelescope<cr>", desc = "Find TODOs" },
    {
      "]t",
      function()
        require("todo-comments").jump_next()
      end,
      desc = "Next TODO",
    },
    {
      "[t",
      function()
        require("todo-comments").jump_prev()
      end,
      desc = "Previous TODO",
    },
  },
}
