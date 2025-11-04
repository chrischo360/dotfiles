-- Plugin: nvim-treesitter
-- Description: Better syntax highlighting and code understanding using tree-sitter parsers.
--              Makes code more readable with accurate, context-aware highlighting.

return {
  "nvim-treesitter/nvim-treesitter",
  build = ":TSUpdate",
  event = { "BufReadPre", "BufNewFile" },
  config = function()
    local treesitter = require("nvim-treesitter.configs")
    treesitter.setup({
      highlight = {
        enable = true,
      },
      indent = { enable = true },
      ensure_installed = {
        "lua",
        "vim",
        "javascript",
        "typescript",
        "html",
        "css",
        "json",
        "markdown",
        "markdown_inline",
        "swift",
      },
    })
  end,
}
