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
    require("markdown-togglecheck").setup({
      create = false, -- Don't auto-create, only toggle existing
      remove = false, -- Uncheck instead of removing when toggling checked boxes
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
