-- Theme: Tokyo Night
-- Description: Clean, dark theme with deep blue background and vibrant colors.
-- Variants: tokyonight-night (default), tokyonight-storm (lighter), tokyonight-day (light), tokyonight-moon (darker)

return {
  "folke/tokyonight.nvim",
  lazy = true,
  priority = 1000,
  opts = {
    style = "night", -- night, storm, day, or moon
    light_style = "day",
    transparent = false,
    terminal_colors = true,
    styles = {
      comments = { italic = true },
      keywords = { italic = true },
      functions = {},
      variables = {},
      sidebars = "dark",
      floats = "dark",
    },
    sidebars = { "qf", "help", "vista_kind", "terminal", "packer" },
    day_brightness = 0.3,
    hide_inactive_statusline = false,
    dim_inactive = false,
    lualine_bold = false,
  },
  config = function(_, opts)
    require("tokyonight").setup(opts)
  end,
}
