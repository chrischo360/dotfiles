-- Theme: Nord
-- Description: Arctic, north-bluish color theme with subtle, cool tones.
-- Variants: nord

return {
  "shaunsingh/nord.nvim",
  lazy = true, -- Only load when explicitly requested
  priority = 1000,
  config = function()
    vim.g.nord_contrast = true
    vim.g.nord_borders = false
    vim.g.nord_disable_background = false
    vim.g.nord_italic = true
    vim.g.nord_uniform_diff_background = true
    vim.g.nord_bold = false
  end,
}
