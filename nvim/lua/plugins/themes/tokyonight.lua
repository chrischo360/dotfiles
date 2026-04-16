-- Theme: Tokyo Night
-- Description: Dark theme with neon colors inspired by Tokyo's night lights.
-- Variants: tokyonight, tokyonight-moon, tokyonight-storm, tokyonight-day

return {
  "folke/tokyonight.nvim",
  enabled = true,
  priority = 1000,
  config = function()
    local mode = vim.fn.readfile(vim.fn.expand("~/.config/theme-mode"))[1] or "dark"
    local style = mode == "light" and "day" or "night"
    require("tokyonight").setup({
      style = style,
      transparent = false,
      terminal_colors = true,
    })
    vim.cmd.colorscheme("tokyonight")
    require("config.highlights")[mode == "light" and "light" or "dark"]()
  end,
}
