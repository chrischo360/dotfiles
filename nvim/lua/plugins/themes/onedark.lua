-- Theme: OneDark Pro
-- Description: Atom's iconic One Dark theme with multiple variants (onedark, onedark_vivid, onedark_dark).
-- Variants: onedark, onedark_vivid (more saturated), onedark_dark (deeper blacks)

return {
  "olimorris/onedarkpro.nvim",
  priority = 1000,
  opts = {
    options = {
      transparency = false,
      terminal_colors = true,
      lualine_transparency = false,
      highlight_inactive_windows = false,
    },
    styles = {
      comments = "italic",
      keywords = "bold",
      functions = "NONE",
      variables = "NONE",
    },
  },
  config = function(_, opts)
    require("onedarkpro").setup(opts)
  end,
}
