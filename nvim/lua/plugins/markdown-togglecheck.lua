-- Plugin: markdown-togglecheck
-- Description: Simple and fast checkbox toggling for markdown files
-- Keybindings: <leader>tt (toggle checkbox [ ] <-> [x])
-- Test

return {
  "nfrid/markdown-togglecheck",
  dependencies = { "nfrid/treesitter-utils" },
  ft = { "markdown" },
  keys = {
    {
      "<leader>tt",
      "<cmd>lua require('markdown-togglecheck').toggle()<cr>",
      desc = "Toggle markdown checkbox",
      ft = "markdown",
    },
  },
}
