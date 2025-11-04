return {
  "rebelot/kanagawa.nvim",
  priority = 1000,
  opts = {
    compile = false,
    undercurl = true,
    commentStyle = { italic = true },
    functionStyle = {},
    keywordStyle = { italic = true },
    statementStyle = { bold = true },
    typeStyle = {},
    transparent = false,
    dimInactive = false,
    terminalColors = true,
    colors = {
      palette = {},
      theme = { wave = {}, lotus = {}, dragon = {}, all = {} },
    },
    theme = "wave", -- wave (default), dragon (darker), lotus (light)
    background = {
      dark = "wave",
      light = "lotus"
    },
  },
  config = function(_, opts)
    require("kanagawa").setup(opts)
  end,
}
