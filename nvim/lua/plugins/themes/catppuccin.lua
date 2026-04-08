-- Theme: Catppuccin
-- Description: Soothing pastel theme with dark and light variants.
-- Variants: mocha, macchiato, frappe (dark), latte (light)

return {
  "catppuccin/nvim",
  name = "catppuccin",
  enabled = false,
  priority = 1000,
  config = function()
    local mode = vim.fn.readfile(vim.fn.expand("~/.config/theme-mode"))[1] or "dark"
    local flavour = vim.g.catppuccin_flavour or (mode == "light" and "latte" or "mocha")
    require("catppuccin").setup({
      flavour = flavour,
      transparent_background = false,
      term_colors = true,
    })
    vim.cmd.colorscheme("catppuccin-" .. flavour)
    require("config.highlights")[mode == "light" and "light" or "dark"]()
  end,
}
