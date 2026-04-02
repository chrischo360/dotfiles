-- Theme: Everforest
-- Description: Comfortable green-tinted dark theme inspired by natural colors.
-- Variants: everforest (dark/light, soft/medium/hard contrast)

return {
  "sainnhe/everforest",
  enabled = false,
  priority = 1000,
  config = function()
    local mode = vim.fn.readfile(vim.fn.expand("~/.config/theme-mode"))[1] or "dark"
    vim.o.background = mode
    vim.g.everforest_background = "hard"
    vim.cmd.colorscheme("everforest")
    require("config.highlights")[mode == "light" and "light" or "dark"]()
  end,
}
