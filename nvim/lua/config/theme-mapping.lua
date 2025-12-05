-- Theme Mapping: Alacritty → Neovim
-- Maps Alacritty theme names to their corresponding Neovim colorscheme names
-- Curated collection of 50 themes (25 light + 25 dark)

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
  "dawnfox",
  "terafox",
  "solarized",
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
-- THEME NAME TRANSLATIONS
-- =============================================================================
-- Format: [alacritty_theme_name] = "neovim_colorscheme_name"

M.theme_map = {
  -- ========== LIGHT THEMES ==========

  -- Soft & Low Contrast
  rose_pine_dawn = "rose-pine-dawn",
  catppuccin_latte = "catppuccin-latte",
  papercolor_light = "PaperColor",
  ayu_light = "ayu-light",
  everforest_light = "everforest",

  -- Professional & Clean
  github_light_default = "github_light",
  github_light_high_contrast = "github_light_high_contrast",
  solarized_light = "solarized",
  one_light = "onelight",
  selenized_light = "solarized",  -- Close alternative

  -- Warm & Earthy
  gruvbox_light = "gruvbox",
  gruvbox_material_medium_light = "gruvbox-material",
  gruvbox_material_hard_light = "gruvbox-material",
  gruvbox_material_soft_light = "gruvbox-material",
  kimbie_light = "gruvbox",  -- Fallback to gruvbox for similar feel

  -- Modern & Bright
  dayfox = "dayfox",
  pencil_light = "PaperColor",  -- Similar aesthetic
  noctis_lux = "github_light",  -- Fallback
  seoul256_light = "PaperColor",  -- Fallback

  -- Minimal & Clean
  alabaster = "PaperColor",
  enfocado_light = "github_light",
  nord_light = "rose-pine-dawn",  -- Closest alternative
  ashes_light = "github_light",

  -- Accessibility
  github_light_colorblind = "github_light_colorblind",
  night_owlish_light = "github_light",

  -- Japanese Inspired
  kanagawa_lotus = "kanagawa-lotus",

  -- ========== DARK THEMES ==========

  -- High Contrast & Vibrant
  dracula = "dracula",
  tokyo_night = "tokyonight-night",
  tokyo_night_storm = "tokyonight-storm",
  tokyo_night_enhanced = "tokyonight-night",
  monokai_pro = "monokai-pro",
  monokai = "monokai-pro",
  monokai_charcoal = "monokai-pro",
  nightfox = "nightfox",

  -- Low Contrast & Muted
  rose_pine = "rose-pine",
  rose_pine_moon = "rose-pine-moon",
  nord = "nord",
  everforest_dark = "everforest",
  ayu_dark = "ayu-dark",
  ayu_mirage = "ayu-dark",

  -- Warm & Retro
  kanagawa_wave = "kanagawa-wave",
  kanagawa_dragon = "kanagawa-dragon",
  gruvbox_dark = "gruvbox",
  gruvbox_material_hard_dark = "gruvbox-material",
  gruvbox_material_medium_dark = "gruvbox-material",
  gruvbox_material_soft_dark = "gruvbox-material",
  gruvbox_material = "gruvbox-material",
  ["gruvbox-material"] = "gruvbox-material",
  one_dark = "onedark",

  -- Pastel & Soft
  catppuccin_mocha = "catppuccin-mocha",
  catppuccin_frappe = "catppuccin-frappe",
  catppuccin_macchiato = "catppuccin-macchiato",
  catppuccin = "catppuccin-mocha",  -- Default to mocha

  -- Modern & Professional
  github_dark_default = "github_dark",
  github_dark = "github_dark",
  github_dark_dimmed = "github_dark_dimmed",
  github_dark_high_contrast = "github_dark_high_contrast",
  carbonfox = "carbonfox",
  duskfox = "duskfox",

  -- Classic & Timeless
  solarized_dark = "solarized",
  solarized_osaka = "solarized",
  oxocarbon = "oxocarbon",

  -- Unique & Stylish
  nightfly = "nightfly",
  palenight = "palenight",
  horizon_dark = "horizon",

  -- Additional Nightfox variants
  nordfox = "nordfox",
  dawnfox = "dawnfox",
  terafox = "terafox",

  -- Dracula variants
  dracula_plus = "dracula",
  ["dracula-soft"] = "dracula-soft",
}

-- =============================================================================
-- FALLBACK THEMES
-- =============================================================================
M.fallback = {
  light = "rose-pine-dawn",  -- Default light theme
  dark = "dracula",          -- Default dark theme
}

-- =============================================================================
-- HELPER FUNCTIONS
-- =============================================================================

-- Function to get Neovim colorscheme from Alacritty theme name
function M.get_nvim_theme(alacritty_theme, appearance)
  -- Check if we have a direct mapping
  local nvim_theme = M.theme_map[alacritty_theme]

  if nvim_theme then
    return nvim_theme
  end

  -- No mapping found, use fallback
  if appearance == "light" then
    return M.fallback.light
  else
    return M.fallback.dark
  end
end

-- Function to get all available themes
function M.get_all_themes()
  return M.all_themes
end

-- Function to get themes for current appearance (kept for backward compatibility)
function M.get_themes_for_appearance(appearance)
  if appearance == "light" then
    return M.light_themes
  else
    return M.dark_themes
  end
end

-- Function to check if a theme is valid for current appearance
function M.is_theme_for_appearance(theme_name, appearance)
  local themes_list = M.get_themes_for_appearance(appearance)
  for _, theme in ipairs(themes_list) do
    if theme == theme_name then
      return true
    end
  end
  return false
end

return M
