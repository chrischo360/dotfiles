-- Theme: Dracula
-- Description: Popular purple/pink dark theme with high contrast and vibrant colors.
-- Variants: dracula, dracula-soft

return {
  "Mofiqul/dracula.nvim",
  priority = 1000,
  opts = {
    transparent_bg = false,
    italic_comment = true,
  },
  config = function(_, opts)
    require("dracula").setup(opts)

    -- Set variant: "dracula" (default) or "dracula-soft"
    vim.cmd.colorscheme("dracula")  -- Change to "dracula-soft" for softer colors

    -- Custom markdown heading colors for render-markdown.nvim
    vim.api.nvim_set_hl(0, "RenderMarkdownH1Bg", { bg = "#a3e635", fg = "#1a1a1a", bold = true })  -- Green
    vim.api.nvim_set_hl(0, "RenderMarkdownH2Bg", { bg = "#60a5fa", fg = "#1a1a1a", bold = true })  -- Blue
    vim.api.nvim_set_hl(0, "RenderMarkdownH3Bg", { bg = "#f87171", fg = "#1a1a1a", bold = true })  -- Red
    vim.api.nvim_set_hl(0, "RenderMarkdownH4Bg", { bg = "#fb923c", fg = "#1a1a1a", bold = true })  -- Orange
    vim.api.nvim_set_hl(0, "RenderMarkdownH5Bg", { bg = "#2dd4bf", fg = "#1a1a1a", bold = true })  -- Teal
    vim.api.nvim_set_hl(0, "RenderMarkdownH6Bg", { bg = "#c084fc", fg = "#1a1a1a", bold = true })  -- Purple
  end,
}
