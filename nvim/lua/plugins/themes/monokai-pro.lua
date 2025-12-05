-- Theme: Monokai Pro
-- Description: Professional Monokai with multiple filter variants.
-- Variants: monokai-pro (default), monokai-pro-classic, monokai-pro-machine, monokai-pro-octagon, monokai-pro-ristretto, monokai-pro-spectrum

return {
  "loctvl841/monokai-pro.nvim",
  lazy = true,
  priority = 1000,
  config = function()
    require("monokai-pro").setup({
      transparent_background = false,
      terminal_colors = true,
      devicons = true,
      styles = {
        comment = { italic = true },
        keyword = { italic = true },
        type = { italic = true },
        storageclass = { italic = true },
        structure = { italic = true },
        parameter = { italic = true },
        annotation = { italic = true },
        tag_attribute = { italic = true },
      },
      filter = "pro", -- classic | octagon | pro | machine | ristretto | spectrum
      inc_search = "background", -- underline | background
      background_clear = {
        "float_win",
        "toggleterm",
        "telescope",
        "which-key",
        "renamer",
        "notify",
      },
      plugins = {
        bufferline = {
          underline_selected = false,
          underline_visible = false,
        },
        indent_blankline = {
          context_highlight = "default",
          context_start_underline = false,
        },
      },
    })
  end,
}
