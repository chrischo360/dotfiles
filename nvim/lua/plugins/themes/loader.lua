-- Applies the active theme at startup by reading ~/.config/active-theme and ~/.config/theme-mode
return {
  name = "theme-loader",
  dir = vim.fn.stdpath("config"),
  priority = 900,
  config = function()
    require("config.theme").load()
  end,
}
