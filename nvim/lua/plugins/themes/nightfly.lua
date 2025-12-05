-- Theme: Nightfly
-- Description: Dark theme with carefully designed syntax highlighting.
-- Variants: nightfly (dark only)

return {
  "bluz71/vim-nightfly-colors",
  name = "nightfly",
  lazy = true,
  priority = 1000,
  config = function()
    vim.g.nightflyTransparent = false
    vim.g.nightflyTerminalColors = true
    vim.g.nightflyItalics = true
    vim.g.nightflyUnderlineMatchParen = false
    vim.g.nightflyNormalFloat = false
  end,
}
