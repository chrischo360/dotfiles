-- Theme: Rose Pine
-- Description: Low-contrast theme with main (dark), moon (dark, higher contrast), and dawn (light) variants.
-- Variants: rose-pine, rose-pine-main, rose-pine-moon, rose-pine-dawn

return {
  "rose-pine/neovim",
  name = "rose-pine",
  lazy = true, -- Only load when explicitly requested
  priority = 1000,
  opts = {
    variant = "auto", -- auto, main, moon, or dawn
    dark_variant = "main", -- main, moon, or dawn
    dim_inactive_windows = false,
    extend_background_behind_borders = true,

    enable = {
      terminal = true,
      legacy_highlights = true,
      migrations = true,
    },

    styles = {
      bold = true,
      italic = true,
      transparency = false,
    },

    groups = {
      border = "muted",
      link = "iris",
      panel = "surface",

      error = "love",
      hint = "iris",
      info = "foam",
      note = "pine",
      todo = "rose",
      warn = "gold",

      git_add = "foam",
      git_change = "rose",
      git_delete = "love",
      git_dirty = "rose",
      git_ignore = "muted",
      git_merge = "iris",
      git_rename = "pine",
      git_stage = "iris",
      git_text = "rose",
      git_untracked = "subtle",

      h1 = "iris",
      h2 = "foam",
      h3 = "rose",
      h4 = "gold",
      h5 = "pine",
      h6 = "foam",
    },

    highlight_groups = {
      Comment = { italic = true },
      VertSplit = { fg = "muted", bg = "muted" },
    },
  },
  config = function(_, opts)
    require("rose-pine").setup(opts)
  end,
}
