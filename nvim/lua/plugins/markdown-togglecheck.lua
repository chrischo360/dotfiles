-- Plugin: markdown-togglecheck
-- Description: Simple and fast checkbox toggling for markdown files
-- Keybindings:
--   <leader>tt - Toggle checkbox [ ] <-> [x]
--   <leader>tT - Insert new checkbox "- [ ] "

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
        require("markdown-togglecheck").toggle()
      end,
      desc = "Toggle markdown checkbox",
      ft = "markdown",
    },
    {
      "<leader>tT",
      "i- [ ] <Esc>",
      desc = "Insert new checkbox",
      ft = "markdown",
    },
  },
}
