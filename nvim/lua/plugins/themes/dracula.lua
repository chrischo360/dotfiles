-- Theme: Dracula
-- Description: Popular purple/pink dark theme with high contrast and vibrant colors.
-- Variants: dracula, dracula-soft

return {
  "Mofiqul/dracula.nvim",
  priority = 1000,
  opts = {
    transparent_bg = false,
    italic_comment = true,
  },
  config = function(_, opts)
    require("dracula").setup(opts)
  end,
}
