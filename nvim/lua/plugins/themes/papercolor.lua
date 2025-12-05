-- Theme: PaperColor
-- Description: Light and dark theme inspired by Google's Material Design.
-- Variants: PaperColor (light/dark togglable with set background)

return {
  "NLKNguyen/papercolor-theme",
  lazy = true,
  priority = 1000,
  config = function()
    vim.g.PaperColor_Theme_Options = {
      theme = {
        default = {
          transparent_background = 0,
          allow_bold = 1,
          allow_italic = 1,
        }
      }
    }
  end,
}
