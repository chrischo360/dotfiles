-- Theme: Tokyo Night
-- Description: Dark theme with neon colors inspired by Tokyo's night lights.
-- Variants: tokyonight, tokyonight-moon, tokyonight-storm, tokyonight-day

return {
  "folke/tokyonight.nvim",
  enabled = true,
  priority = 1000,
  opts = {
    style = "night",  -- "night", "moon", "storm", or "day"
    transparent = false,
    terminal_colors = true,
  },
  config = function(_, opts)
    require("tokyonight").setup(opts)
    vim.cmd.colorscheme("tokyonight")
    require("config.highlights").dark()  -- Apply shared dark theme highlights
  end,
}
