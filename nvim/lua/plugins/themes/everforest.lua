-- Theme: Everforest
-- Description: Comfortable green forest theme inspired by gruvbox. Supports both dark and light modes.
-- Variants: everforest (respects vim.o.background setting)

return {
  "neanias/everforest-nvim",
  lazy = true, -- Only load when explicitly requested
  priority = 1000,
  opts = {
    background = "hard", -- hard, medium, soft
    transparent_background_level = 0,
    italics = true,
    disable_italic_comments = false,
  },
  config = function(_, opts)
    require("everforest").setup(opts)
  end,
}
