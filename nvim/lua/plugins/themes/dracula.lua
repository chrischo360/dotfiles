return {
  "Mofiqul/dracula.nvim",
  priority = 1000,
  opts = {
    transparent_bg = false,
    italic_comment = true,
  },
  config = function(_, opts)
    require("dracula").setup(opts)
  end,
}
