-- Theme: Gruvbox
-- Description: Retro groove color scheme with warm, neutral colors.
-- Variants: gruvbox (dark), gruvbox-light

return {
  "morhetz/gruvbox",
  enabled = false,
  priority = 1000,
  init = function()
    local mode = vim.fn.readfile(vim.fn.expand("~/.config/theme-mode"))[1] or "dark"
    vim.o.background = mode
  end,
  config = function()
    vim.cmd.colorscheme("gruvbox")
    local mode = vim.o.background
    require("config.highlights")[mode == "light" and "light" or "dark"]()
  end,
}
