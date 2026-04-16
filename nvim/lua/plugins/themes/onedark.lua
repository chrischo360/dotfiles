-- Theme: OneDark
-- Description: Atom-inspired dark theme with multiple style variations.
-- Variants: dark, darker, cool, deep, warm, warmer

return {
  "navarasu/onedark.nvim",
  enabled = false,
  priority = 1000,
  opts = {
    style = "dark",
    transparent = false,
    term_colors = true,
  },
  config = function(_, opts)
    require("onedark").setup(opts)
    require("onedark").load()
    require("config.highlights").dark()
  end,
}
