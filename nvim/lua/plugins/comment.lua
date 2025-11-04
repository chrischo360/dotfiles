-- Plugin: Comment.nvim
-- Description: Smart commenting with proper JSX block comment support
-- Keybindings:
--   gcc - Toggle line comment
--   gc (visual mode) - Toggle comment on selection
--   gbc - Toggle block comment
--   gb (visual mode) - Toggle block comment on selection

return {
  "numToStr/Comment.nvim",
  dependencies = { "JoosepAlviste/nvim-ts-context-commentstring" },
  event = { "BufReadPre", "BufNewFile" },
  config = function()
    require("Comment").setup({
      pre_hook = require("ts_context_commentstring.integrations.comment_nvim").create_pre_hook(),
      -- Use block comments for JSX in visual mode
      toggler = {
        line = 'gcc',
        block = 'gbc',
      },
      opleader = {
        line = 'gc',
        block = 'gb',
      },
    })
  end,
}
