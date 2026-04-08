-- Theme: Rose Pine
-- Description: Elegant dark theme with muted, warm tones.
-- Variants: main, moon, dawn (light)

return {
  "rose-pine/neovim",
  name = "rose-pine",
  enabled = false,
  priority = 1000,
  config = function()
    local mode = vim.fn.readfile(vim.fn.expand("~/.config/theme-mode"))[1] or "dark"
    require("rose-pine").setup({
      variant = mode == "light" and "dawn" or "main",
      dark_variant = "main",
    })
    vim.cmd.colorscheme("rose-pine")
    require("config.highlights")[mode == "light" and "light" or "dark"]()
  end,
}
