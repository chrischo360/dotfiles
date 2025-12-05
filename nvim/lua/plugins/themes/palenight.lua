-- Theme: Palenight
-- Description: Material palenight color scheme.
-- Variants: palenight (dark only)

return {
  "drewtempelmeyer/palenight.vim",
  lazy = true,
  priority = 1000,
  config = function()
    vim.g.palenight_terminal_italics = 1
    vim.g.palenight_color_overrides = {}
  end,
}
