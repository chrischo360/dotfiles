-- Plugin: markdown-togglecheck
-- Description: Simple and fast checkbox toggling for markdown files
-- Keybindings:
--   <leader>tt - Toggle checkbox [ ] <-> [x] (supports dot-repeat with '.')
--   <leader>tT - Toggle checkbox (always creates [ ] if missing, supports dot-repeat)

return {
  "nfrid/markdown-togglecheck",
  dependencies = { "nfrid/treesitter-utils" },
  ft = { "markdown" },
  config = function()
    -- Shim nvim-treesitter.ts_utils for main branch compatibility
    -- markdown-togglecheck only uses get_node_at_cursor()
    package.loaded["nvim-treesitter.ts_utils"] = {
      get_node_at_cursor = function()
        return vim.treesitter.get_node()
      end,
    }
    require("markdown-togglecheck").setup({
      create = false,
      remove = false,
    })
  end,
  keys = {
    {
      "<leader>tt",
      function()
        vim.go.operatorfunc = "v:lua.require'markdown-togglecheck'.toggle"
        return "g@l"
      end,
      expr = true,
      desc = "Toggle markdown checkbox",
      ft = "markdown",
    },
    {
      "<leader>tT",
      function()
        vim.go.operatorfunc = "v:lua.require'markdown-togglecheck'.toggle_box"
        return "g@l"
      end,
      expr = true,
      desc = "Toggle checkbox (always creates [ ])",
      ft = "markdown",
    },
  },
}
