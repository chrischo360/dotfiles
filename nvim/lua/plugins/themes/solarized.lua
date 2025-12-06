-- Theme: Solarized
-- Description: Precision colors for machines and people. Scientifically designed.
-- Variants: solarized (dark/light togglable)

return {
  "maxmx03/solarized.nvim",
  lazy = true,
  priority = 1000,
  opts = {
    transparent = {
      enabled = false,
    },
    palette = 'solarized', -- solarized or selenized
    styles = {
      comments = { italic = true, bold = false },
      functions = { italic = false, bold = false },
      variables = { italic = false, bold = false },
    },
    enables = {
      bufferline = true,
      cmp = true,
      diagnostic = true,
      dashboard = true,
      editor = true,
      gitsign = true,
      hop = true,
      lsp = true,
      lspsaga = true,
      navic = true,
      neogit = true,
      neotree = true,
      notify = true,
      noice = true,
      semantic = true,
      syntax = true,
      telescope = true,
      tree = true,
      treesitter = true,
      todo = true,
      whichkey = true,
      mini = true,
    },
  },
  config = function(_, opts)
    vim.o.termguicolors = true
    vim.o.background = 'dark'
    require('solarized').setup(opts)
  end,
}
