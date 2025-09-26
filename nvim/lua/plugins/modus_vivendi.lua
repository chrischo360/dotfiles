return {
  "miikanissi/modus-themes.nvim",
  name = "modus-themes",
  priority = 1000,
  opts = {
    style = "modus_vivendi", -- Force dark theme
    variant = "default",
    transparent = false, -- Transparency disabled as requested
    dim_inactive = false,
    hide_inactive_statusline = false,
    styles = {
      comments = { italic = true },
      keywords = { italic = true },
    },
  },
  config = function(_, opts)
    require("modus-themes").setup(opts)
    -- Load the colorscheme
    vim.cmd.colorscheme("modus")
  end,
}
