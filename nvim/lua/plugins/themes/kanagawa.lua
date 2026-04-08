-- Theme: Kanagawa
-- Description: Japanese ink painting inspired theme with muted warm tones.
-- Variants: wave, dragon (dark), lotus (light)

return {
  "rebelot/kanagawa.nvim",
  enabled = false,
  priority = 1000,
  config = function()
    local mode = vim.fn.readfile(vim.fn.expand("~/.config/theme-mode"))[1] or "dark"
    require("kanagawa").setup({
      theme = mode == "light" and "lotus" or "wave",
      transparent = false,
      terminalColors = true,
    })
    vim.cmd.colorscheme(mode == "light" and "kanagawa-lotus" or "kanagawa-wave")
    require("config.highlights")[mode == "light" and "light" or "dark"]()
  end,
}
