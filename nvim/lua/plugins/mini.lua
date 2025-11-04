-- Plugin: mini.nvim
-- Description: Collection of minimal useful plugins. Currently includes mini.pairs for auto-pairing brackets.

return {
  "echasnovski/mini.nvim",
  version = false,
  config = function()
    require("mini.pairs").setup()
  end,
}
