return {
  "neanias/everforest-nvim",
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
