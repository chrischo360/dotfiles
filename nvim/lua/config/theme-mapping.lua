-- Theme Registry
-- Metadata for Neovim themes (used by theme picker)

local M = {}

-- =============================================================================
-- LIGHT THEMES (unique list for metadata/reference)
-- =============================================================================
M.light_themes = {
  "rose-pine-dawn",
  "catppuccin-latte",
  "PaperColor",
  "ayu-light",
  "everforest",
  "github_light",
  "github_light_high_contrast",
  "github_light_colorblind",
  "solarized",
  "onelight",
  "gruvbox",
  "dayfox",
  "dawnfox",
  "kanagawa-lotus",
}

-- =============================================================================
-- DARK THEMES (unique list for metadata/reference)
-- =============================================================================
M.dark_themes = {
  "dracula",
  "tokyonight-night",
  "tokyonight-storm",
  "monokai-pro",
  "nightfox",
  "rose-pine",
  "rose-pine-moon",
  "nord",
  "everforest",
  "ayu-dark",
  "kanagawa-wave",
  "kanagawa-dragon",
  "gruvbox",
  "gruvbox-material",
  "onedark",
  "catppuccin-mocha",
  "catppuccin-frappe",
  "catppuccin-macchiato",
  "github_dark",
  "github_dark_dimmed",
  "github_dark_high_contrast",
  "carbonfox",
  "duskfox",
  "nordfox",
  "terafox",
  "oxocarbon",
  "nightfly",
  "palenight",
  "horizon",
}

-- =============================================================================
-- ALL THEMES (combined unique list for theme picker)
-- =============================================================================
M.all_themes = {
  -- Light themes
  "rose-pine-dawn",
  "catppuccin-latte",
  "PaperColor",
  "ayu-light",
  "github_light",
  "github_light_high_contrast",
  "github_light_colorblind",
  "onelight",
  "dayfox",
  "dawnfox",
  "kanagawa-lotus",

  -- Dark themes
  "dracula",
  "tokyonight-night",
  "tokyonight-storm",
  "monokai-pro",
  "nightfox",
  "rose-pine",
  "rose-pine-moon",
  "nord",
  "ayu-dark",
  "kanagawa-wave",
  "kanagawa-dragon",
  "gruvbox-material",
  "onedark",
  "catppuccin-mocha",
  "catppuccin-frappe",
  "catppuccin-macchiato",
  "github_dark",
  "github_dark_dimmed",
  "github_dark_high_contrast",
  "carbonfox",
  "duskfox",
  "nordfox",
  "terafox",
  "oxocarbon",
  "nightfly",
  "palenight",
  "horizon",

  -- Dual mode themes (work in both light and dark)
  "everforest",
  "gruvbox",
  "solarized",
}


-- =============================================================================
-- HELPER FUNCTIONS
-- =============================================================================

-- Function to get all available themes
function M.get_all_themes()
  return M.all_themes
end

-- Function to get theme type: "light", "dark", or "dual"
function M.get_theme_type(theme_name)
  local in_light = vim.tbl_contains(M.light_themes, theme_name)
  local in_dark = vim.tbl_contains(M.dark_themes, theme_name)

  if in_light and in_dark then
    return "dual"
  elseif in_light then
    return "light"
  elseif in_dark then
    return "dark"
  end
  return "unknown"
end

return M
