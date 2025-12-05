-- Colorscheme Configuration
-- Syncs with Alacritty theme based on macOS appearance

-- Import theme mapping
local theme_mapping = require("config.theme-mapping")

-- Function to detect macOS appearance
local function get_macos_appearance()
  local handle = io.popen("defaults read -g AppleInterfaceStyle 2>/dev/null")
  if not handle then
    return "dark" -- Fallback to dark if can't detect
  end
  local result = handle:read("*a")
  handle:close()
  return result:match("Dark") and "dark" or "light"
end

-- Function to read Alacritty theme preferences
local function get_alacritty_theme_pref()
  local appearance = get_macos_appearance()
  local prefs_file = vim.fn.expand("~/.config/alacritty/theme-prefs.conf")

  -- Check if file exists
  local file = io.open(prefs_file, "r")
  if not file then
    -- Fallback to defaults if prefs file doesn't exist
    return appearance == "light" and "rose_pine_dawn" or "dracula"
  end

  -- Read preferences
  local content = file:read("*all")
  file:close()

  -- Extract theme based on appearance
  local theme_pref
  if appearance == "light" then
    theme_pref = content:match('LIGHT_THEME="([^"]+)"')
  else
    theme_pref = content:match('DARK_THEME="([^"]+)"')
  end

  return theme_pref or (appearance == "light" and "rose_pine_dawn" or "dracula")
end

-- Function to get coordinated theme
local function get_coordinated_theme()
  local appearance = get_macos_appearance()
  local alacritty_theme = get_alacritty_theme_pref()
  local nvim_theme = theme_mapping.get_nvim_theme(alacritty_theme, appearance)

  return nvim_theme
end

-- Default: Use coordinated theme
local default_colorscheme = get_coordinated_theme()

-- Function to safely set colorscheme
local function set_colorscheme(name)
  local status_ok, _ = pcall(vim.cmd.colorscheme, name)
  if not status_ok then
    vim.notify("Colorscheme '" .. name .. "' not found!", vim.log.levels.WARN)
    return false
  end
  return true
end

-- Set the default colorscheme on startup
-- Themes are lazy-loaded when you switch to them
set_colorscheme(default_colorscheme)

-- Keybinding for theme picker with live preview - ALL THEMES
vim.keymap.set("n", "<leader>th", function()
  -- Save current colorscheme to restore if cancelled
  local current_colorscheme = vim.g.colors_name

  -- Get all available themes
  local all_themes = theme_mapping.get_all_themes()

  -- Header for all themes
  local header = "All Themes"

  local pickers = require('telescope.pickers')
  local finders = require('telescope.finders')
  local conf = require('telescope.config').values
  local actions = require('telescope.actions')
  local action_state = require('telescope.actions.state')

  pickers.new({}, {
    prompt_title = header,
    finder = finders.new_table {
      results = all_themes,
    },
    sorter = conf.generic_sorter({}),
    attach_mappings = function(prompt_bufnr, map)
      -- Apply theme on selection change (live preview)
      local preview_theme = function()
        local selection = action_state.get_selected_entry()
        if selection then
          pcall(vim.cmd.colorscheme, selection.value)
        end
      end

      -- Override arrow keys to trigger preview
      map('i', '<Down>', function()
        actions.move_selection_next(prompt_bufnr)
        preview_theme()
      end)

      map('i', '<Up>', function()
        actions.move_selection_previous(prompt_bufnr)
        preview_theme()
      end)

      map('i', '<C-n>', function()
        actions.move_selection_next(prompt_bufnr)
        preview_theme()
      end)

      map('i', '<C-p>', function()
        actions.move_selection_previous(prompt_bufnr)
        preview_theme()
      end)

      -- Normal mode navigation
      map('n', 'j', function()
        actions.move_selection_next(prompt_bufnr)
        preview_theme()
      end)

      map('n', 'k', function()
        actions.move_selection_previous(prompt_bufnr)
        preview_theme()
      end)

      -- On select (Enter)
      actions.select_default:replace(function()
        local selection = action_state.get_selected_entry()
        actions.close(prompt_bufnr)
        if selection then
          vim.cmd.colorscheme(selection.value)
        end
      end)

      -- On cancel (ESC)
      map('i', '<Esc>', function()
        actions.close(prompt_bufnr)
        if current_colorscheme then
          vim.cmd.colorscheme(current_colorscheme)
        end
      end)

      map('n', '<Esc>', function()
        actions.close(prompt_bufnr)
        if current_colorscheme then
          vim.cmd.colorscheme(current_colorscheme)
        end
      end)

      return true
    end,
  }):find()
end, {
  desc = "Theme picker (all themes)",
  noremap = true,
  silent = true,
})

-- Optional: Quick theme switching keybindings
-- Uncomment these if you want dedicated keys for specific themes
-- vim.keymap.set('n', '<leader>tk', function() set_colorscheme('kanagawa-wave') end, { desc = 'Kanagawa Wave' })
-- vim.keymap.set('n', '<leader>tr', function() set_colorscheme('rose-pine') end, { desc = 'Rose Pine' })
-- vim.keymap.set('n', '<leader>to', function() set_colorscheme('onedark') end, { desc = 'OneDark' })
-- vim.keymap.set('n', '<leader>te', function() set_colorscheme('everforest') end, { desc = 'Everforest' })
-- vim.keymap.set('n', '<leader>td', function() set_colorscheme('dracula') end, { desc = 'Dracula' })
-- vim.keymap.set('n', '<leader>tn', function() set_colorscheme('nord') end, { desc = 'Nord' })
