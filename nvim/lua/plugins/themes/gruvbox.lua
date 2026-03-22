-- Theme: Gruvbox
-- Description: Retro groove color scheme with warm, neutral colors.
-- Variants: gruvbox (dark), gruvbox-light

return {
  "morhetz/gruvbox",
  enabled = false,
  priority = 1000,
  init = function()
    vim.o.background = "light"  -- Set BEFORE colorscheme loads
  end,
  config = function()
    vim.cmd.colorscheme("gruvbox")
    require("config.highlights").light()  -- Apply shared light theme highlights
  end,
}
