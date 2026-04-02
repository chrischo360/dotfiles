-- Theme: PaperColor
-- Description: Clean, high-contrast light theme with crisp colors.
-- Variants: PaperColor (light), PaperColor (dark)

return {
  "NLKNguyen/papercolor-theme",
  enabled = false,
  priority = 1000,
  init = function()
    local mode = vim.fn.readfile(vim.fn.expand("~/.config/theme-mode"))[1] or "light"
    vim.o.background = mode
  end,
  config = function()
    vim.cmd.colorscheme("PaperColor")
    local mode = vim.o.background
    require("config.highlights")[mode == "light" and "light" or "dark"]()
  end,
}
