-- Plugin: mini.nvim
-- Description: Collection of minimal useful plugins. Currently includes mini.comment for smart commenting.
-- Keybindings: gc (comment/uncomment), gcc (comment line)

return {
  "echasnovski/mini.nvim",
  version = false,
  config = function()
    require("mini.comment").setup()
    require("mini.pairs").setup()
  end,
}
