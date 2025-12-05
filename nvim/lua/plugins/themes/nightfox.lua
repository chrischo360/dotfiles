-- Theme: Nightfox
-- Description: Modern theme family with multiple fox-themed variants.
-- Variants: nightfox, dayfox (light), dawnfox (light), duskfox (dark), nordfox (nord-like), terafox, carbonfox

return {
  "EdenEast/nightfox.nvim",
  lazy = true,
  priority = 1000,
  opts = {
    options = {
      compile_path = vim.fn.stdpath("cache") .. "/nightfox",
      compile_file_suffix = "_compiled",
      transparent = false,
      terminal_colors = true,
      dim_inactive = false,
      module_default = true,
      colorblind = {
        enable = false,
        simulate_only = false,
        severity = {
          protan = 0,
          deutan = 0,
          tritan = 0,
        },
      },
      styles = {
        comments = "italic",
        conditionals = "NONE",
        constants = "NONE",
        functions = "NONE",
        keywords = "NONE",
        numbers = "NONE",
        operators = "NONE",
        strings = "NONE",
        types = "NONE",
        variables = "NONE",
      },
      inverse = {
        match_paren = false,
        visual = false,
        search = false,
      },
    },
  },
  config = function(_, opts)
    require("nightfox").setup(opts)
  end,
}
