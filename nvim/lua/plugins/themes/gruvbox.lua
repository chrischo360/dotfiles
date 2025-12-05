-- Theme: Gruvbox
-- Description: Retro groove theme with warm, earthy tones.
-- Variants: gruvbox (dark/light togglable)

return {
  "ellisonleao/gruvbox.nvim",
  lazy = true,
  priority = 1000,
  opts = {
    terminal_colors = true,
    undercurl = true,
    underline = true,
    bold = true,
    italic = {
      strings = true,
      emphasis = true,
      comments = true,
      operators = false,
      folds = true,
    },
    strikethrough = true,
    invert_selection = false,
    invert_signs = false,
    invert_tabline = false,
    invert_intend_guides = false,
    inverse = true,
    contrast = "", -- can be "hard", "soft" or empty string
    palette_overrides = {},
    overrides = {},
    dim_inactive = false,
    transparent_mode = false,
  },
  config = function(_, opts)
    require("gruvbox").setup(opts)
  end,
}
