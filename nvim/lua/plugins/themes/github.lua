-- Theme: GitHub
-- Description: GitHub's official color scheme with dark and light variants.
-- Variants: github_dark_dimmed, github_dark, github_light

return {
  "projekt0n/github-nvim-theme",
  name = "github-theme",
  enabled = false,
  priority = 1000,
  config = function()
    local mode = vim.fn.readfile(vim.fn.expand("~/.config/theme-mode"))[1] or "dark"
    local style = mode == "light" and "github_light" or "github_dark_dimmed"
    require("github-theme").setup({})
    vim.cmd.colorscheme(style)
    require("config.highlights")[mode == "light" and "light" or "dark"]()
  end,
}
