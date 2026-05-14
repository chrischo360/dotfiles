-- Theme entrypoint — applies colorscheme on startup and handles live switching.
-- Active theme is stored in ~/.config/active-theme (e.g. "dracula")
-- Mode is stored in ~/.config/theme-mode ("dark" or "light")

local M = {}

local plugin_map = {
  ["dracula"]            = "dracula.nvim",
  ["onedark"]            = "onedark.nvim",
  ["catppuccin-frappe"]  = "catppuccin",
  ["catppuccin-latte"]   = "catppuccin",
  ["rose-pine-dawn"]     = "rose-pine",
  ["PaperColor"]         = "papercolor-theme",
  ["github_dark_dimmed"] = "github-theme",
  ["github_light"]       = "github-theme",
  ["gruvbox"]            = "gruvbox.nvim",
  ["nightfox"]           = "nightfox.nvim",
  ["carbonfox"]          = "nightfox.nvim",
  ["duskfox"]            = "nightfox.nvim",
  ["dayfox"]             = "nightfox.nvim",
  ["everforest"]         = "everforest-nvim",
  ["solarized"]          = "solarized.nvim",
  ["custom"]             = "gruvbox-material",
}

-- Map theme name + mode -> colorscheme string and any pre-setup needed
local function resolve(theme, mode)
  if theme == "dracula" then
    return "dracula", function()
      require("dracula").setup({
        transparent_bg = false,
        italic_comment = true,
        overrides = function()
          return {
            CursorLine    = { bg = "#1e3a2a" },
            CursorLineNr  = { fg = "#50fa7b", bold = true },
            DiffAdd       = { bg = "#2d4a3e", fg = "NONE" },
            DiffChange    = { bg = "#3d3d1e", fg = "NONE" },
            DiffDelete    = { bg = "#4a2d2d", fg = "#ff5555" },
            DiffText      = { bg = "#5c5c00", fg = "#f1fa8c", bold = true },
            DiffviewDiffAdd    = { bg = "#2d4a3e" },
            DiffviewDiffDelete = { bg = "#4a2d2d" },
            DiffviewDiffChange = { bg = "#3d3d1e" },
            DiffviewDiffText   = { bg = "#5c5c00", fg = "#f1fa8c", bold = true },
            GitSignsAdd    = { fg = "#50fa7b" },
            GitSignsChange = { fg = "#ffb86c" },
            GitSignsDelete = { fg = "#ff5555" },
            GitConflictCurrent  = { bg = "#2d4a3e" },
            GitConflictIncoming = { bg = "#3d3d5c" },
            GitConflictAncestor = { bg = "#3d3d1e" },
          }
        end,
      })
    end

  elseif theme == "onedark" then
    return "onedark", function()
      require("onedark").setup({
        style = mode == "light" and "light" or "dark",
        transparent = false,
        term_colors = true,
      })
    end

  elseif theme == "catppuccin" then
    local flavour = mode == "light" and "latte" or "frappe"
    return "catppuccin-" .. flavour, function()
      require("catppuccin").setup({
        flavour = flavour,
        transparent_background = false,
        term_colors = true,
      })
    end

  elseif theme == "rose-pine" then
    return "rose-pine-dawn", function()
      require("rose-pine").setup({ variant = "dawn" })
    end

  elseif theme == "papercolor" then
    return "PaperColor", function()
      vim.o.background = mode == "light" and "light" or "dark"
    end

  elseif theme == "github-dark" then
    local cs = mode == "light" and "github_light" or "github_dark_dimmed"
    return cs, function()
      require("github-theme").setup({})
    end

  elseif theme == "gruvbox" then
    return "gruvbox", function()
      require("gruvbox").setup({
        contrast = mode == "dark" and "hard" or "soft",
        bold = true,
        italic = { strings = true, comments = true },
      })
      vim.o.background = mode == "light" and "light" or "dark"
    end

  elseif theme == "nightfox" then
    -- dark variants: nightfox, duskfox, carbonfox
    -- light variant: dayfox
    -- nightfox uses pre-compiled themes; setup() not needed for defaults
    local cs = mode == "light" and "dayfox" or "nightfox"
    return cs, function() end

  elseif theme == "carbonfox" then
    return "carbonfox", function() end

  elseif theme == "duskfox" then
    return "duskfox", function() end

  elseif theme == "everforest" then
    return "everforest", function()
      require("everforest").setup({
        background = mode == "light" and "soft" or "hard",
      })
      vim.o.background = mode == "light" and "light" or "dark"
    end

  elseif theme == "solarized" then
    return "solarized", function()
      require("solarized").setup({
        theme = mode == "light" and "neo" or "default",
      })
      vim.o.background = mode == "light" and "light" or "dark"
    end

  elseif theme == "custom" then
    -- Hand-rolled dark/light pair. Tweak colors here to build your own aesthetic.
    -- Currently based on gruvbox-material for a warm earthy base.
    local variant = mode == "light" and "light" or "dark"
    return "gruvbox-material", function()
      vim.g.gruvbox_material_background = mode == "dark" and "hard" or "soft"
      vim.g.gruvbox_material_foreground = "original"
      vim.g.gruvbox_material_enable_italic = 1
      vim.g.gruvbox_material_enable_bold = 1
      vim.o.background = variant
    end

  else
    return nil, nil
  end
end

function M.apply(theme, mode)
  local colorscheme, setup_fn = resolve(theme, mode)
  if not colorscheme then
    return "error: unknown theme: " .. tostring(theme)
  end

  local plugin = plugin_map[colorscheme]
  if not plugin then
    return "error: no plugin for colorscheme: " .. colorscheme
  end

  -- Load plugin if not already loaded
  local ok, lazy = pcall(require, "lazy")
  if ok then
    lazy.load({ plugins = { plugin }, wait = true })
  end

  -- Run theme-specific setup
  local setup_ok, setup_err = pcall(setup_fn)
  if not setup_ok then
    return "error: setup: " .. tostring(setup_err)
  end

  -- Apply colorscheme
  local cs_ok, cs_err = pcall(vim.cmd.colorscheme, colorscheme)
  if not cs_ok then
    return "error: colorscheme: " .. tostring(cs_err)
  end

  -- Apply shared highlight overrides
  local hl_ok, hl_err = pcall(function()
    require("config.highlights")[mode == "light" and "light" or "dark"]()
  end)
  if not hl_ok then
    return "error: highlights: " .. tostring(hl_err)
  end

  return "ok"
end

-- Called from shell for live switching:
--   nvim --server <socket> --remote-expr "v:lua.require('config.theme').switch('dracula', 'dark')"
function M.switch(theme, mode)
  return M.apply(theme, mode)
end

-- Called at startup from init or a loader plugin
function M.load()
  local theme = vim.fn.readfile(vim.fn.expand("~/.config/active-theme"))[1] or "dracula"
  local mode  = vim.fn.readfile(vim.fn.expand("~/.config/theme-mode"))[1]  or "dark"
  M.apply(theme, mode)
end

return M
