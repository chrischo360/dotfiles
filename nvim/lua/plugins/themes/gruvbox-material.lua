-- Theme: Gruvbox Material
-- Description: Improved Gruvbox with softer palette, warm retro colors.
-- Variants: dark, light

return {
  "sainnhe/gruvbox-material",
  enabled = false,
  priority = 1000,
  init = function()
    local mode = vim.fn.readfile(vim.fn.expand("~/.config/theme-mode"))[1] or "dark"
    vim.o.background = mode
    vim.g.gruvbox_material_background = "medium"
    vim.g.gruvbox_material_better_performance = 1
  end,
  config = function()
    vim.cmd.colorscheme("gruvbox-material")
    local mode = vim.o.background
    require("config.highlights")[mode == "light" and "light" or "dark"]()
  end,
}
