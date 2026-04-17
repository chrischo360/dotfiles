-- Remote theme switcher — called from shell via:
--   nvim --server <socket> --remote-expr "v:lua.require('config.theme').switch('catppuccin-mocha', 'dark')"

local M = {}

function M.switch(colorscheme, mode)
  -- Derive plugin name from colorscheme
  local plugin_map = {
    ["catppuccin"]           = "catppuccin",
    ["catppuccin-mocha"]     = "catppuccin",
    ["catppuccin-macchiato"] = "catppuccin",
    ["catppuccin-frappe"]    = "catppuccin",
    ["catppuccin-latte"]     = "catppuccin",
    ["kanagawa-wave"]        = "kanagawa.nvim",
    ["kanagawa-lotus"]       = "kanagawa.nvim",
    ["gruvbox-material"]     = "gruvbox-material",
    ["rose-pine"]            = "rose-pine",
    ["rose-pine-dawn"]       = "rose-pine",
    ["tokyonight"]           = "tokyonight.nvim",
    ["tokyonight-day"]       = "tokyonight.nvim",
    ["dracula"]              = "dracula.nvim",
    ["everforest"]           = "everforest",
    ["onedark"]              = "onedark.nvim",
    ["gruvbox"]              = "gruvbox",
    ["PaperColor"]           = "papercolor-theme",
    ["github_dark_dimmed"]   = "github-theme",
    ["github_light"]         = "github-theme",
  }

  local plugin = plugin_map[colorscheme]
  if not plugin then
    return "error: unknown colorscheme: " .. colorscheme
  end

  -- Load plugin synchronously if not already loaded
  local ok, lazy = pcall(require, "lazy")
  if ok then
    lazy.load({ plugins = { plugin }, wait = true })
  end

  -- Apply colorscheme
  local cs_ok, err = pcall(vim.cmd.colorscheme, colorscheme)
  if not cs_ok then
    return "error: " .. tostring(err)
  end

  -- Apply highlight overrides
  local hl_ok, hl_err = pcall(function()
    require("config.highlights")[mode == "light" and "light" or "dark"]()
  end)
  if not hl_ok then
    return "error: highlights: " .. tostring(hl_err)
  end

  return "ok"
end

return M
