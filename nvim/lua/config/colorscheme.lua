-- Colorscheme Configuration
-- Independent theme management with persistence

-- Import theme mapping for theme picker metadata
local theme_mapping = require("config.theme-mapping")

-- Function to detect macOS appearance
local function get_macos_appearance()
  local handle = io.popen("defaults read -g AppleInterfaceStyle 2>/dev/null")
  if not handle then
    return "light" -- Fallback to light if can't detect
  end
  local result = handle:read("*a")
  handle:close()
  return result:match("Dark") and "dark" or "light"
end

-- Simple fallback themes based on macOS appearance
local function get_fallback_theme()
  local appearance = get_macos_appearance()
  return appearance == "light" and "rose-pine-dawn" or "dracula"
end

-- Function to safely set colorscheme
local function set_colorscheme(name)
  local status_ok, _ = pcall(vim.cmd.colorscheme, name)
  if not status_ok then
    vim.notify("Colorscheme '" .. name .. "' not found!", vim.log.levels.WARN)
    return false
  end
  return true
end

-- Save the selected colorscheme to persist across sessions
local function save_colorscheme(name)
  local file = io.open(vim.fn.stdpath('config') .. '/last-theme.txt', 'w')
  if file then
    -- Save both theme name and background setting
    file:write(name .. '\n' .. vim.o.background)
    file:close()
  end
end

-- Load the last saved colorscheme
local function load_saved_colorscheme()
  local file = io.open(vim.fn.stdpath('config') .. '/last-theme.txt', 'r')
  if file then
    local theme = file:read('*l')  -- Read first line (theme name)
    local bg = file:read('*l')     -- Read second line (background)
    file:close()

    -- Set background first if it was saved
    if bg and (bg == 'light' or bg == 'dark') then
      vim.o.background = bg
    end

    return theme
  end
  return nil
end

-- Set the default colorscheme on startup
-- First try saved theme, then simple fallback
local saved_theme = load_saved_colorscheme()
if saved_theme and saved_theme ~= "" then
  set_colorscheme(saved_theme)
else
  -- Simple fallback on first launch based on macOS appearance
  local appearance = get_macos_appearance()
  vim.o.background = appearance
  set_colorscheme(get_fallback_theme())
end

-- Keybinding for theme picker with live preview - ALL THEMES
vim.keymap.set("n", "<leader>th", function()
  -- Save current colorscheme AND background to restore if cancelled
  local current_colorscheme = vim.g.colors_name
  local current_background = vim.o.background

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
      entry_maker = function(entry)
        local theme_type = theme_mapping.get_theme_type(entry)
        local indicator = ""

        if theme_type == "light" then
          indicator = " (light)"
        elseif theme_type == "dark" then
          indicator = " (dark)"
        elseif theme_type == "dual" then
          indicator = " (dual)"
        end

        return {
          value = entry,
          display = entry .. indicator,
          ordinal = entry .. indicator,
        }
      end
    },
    sorter = conf.generic_sorter({}),
    attach_mappings = function(prompt_bufnr, map)
      -- Apply theme on selection change (live preview)
      local preview_theme = function()
        local selection = action_state.get_selected_entry()
        if selection then
          local theme_type = theme_mapping.get_theme_type(selection.value)

          -- Set appropriate background before applying theme
          if theme_type == "light" then
            vim.o.background = "light"
          elseif theme_type == "dark" then
            vim.o.background = "dark"
          end
          -- For "dual" themes, keep current background

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
          local theme_type = theme_mapping.get_theme_type(selection.value)

          -- Set appropriate background before applying theme
          if theme_type == "light" then
            vim.o.background = "light"
          elseif theme_type == "dark" then
            vim.o.background = "dark"
          end
          -- For "dual" themes, keep current background

          vim.cmd.colorscheme(selection.value)
          save_colorscheme(selection.value)  -- Save as default for future sessions
        end
      end)

      -- On cancel (ESC)
      map('i', '<Esc>', function()
        actions.close(prompt_bufnr)
        if current_colorscheme then
          -- Restore both background and colorscheme
          vim.o.background = current_background
          vim.cmd.colorscheme(current_colorscheme)
        end
      end)

      map('n', '<Esc>', function()
        actions.close(prompt_bufnr)
        if current_colorscheme then
          -- Restore both background and colorscheme
          vim.o.background = current_background
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

-- Sync theme across Neovim instances on window focus
local last_checked_content = ""

vim.api.nvim_create_autocmd("FocusGained", {
  callback = function()
    local file = io.open(vim.fn.stdpath('config') .. '/last-theme.txt', 'r')
    if not file then return end

    local theme = file:read('*l')
    local bg = file:read('*l')
    file:close()

    local new_content = (theme or "") .. "\n" .. (bg or "")

    -- Only reload if file changed
    if new_content ~= last_checked_content then
      last_checked_content = new_content

      -- Set background first
      if bg and (bg == 'light' or bg == 'dark') then
        vim.o.background = bg
      end

      -- Always reload colorscheme after background change to apply new colors
      -- Even if theme name is the same, it needs to reload for background change
      if theme and theme ~= "" then
        pcall(vim.cmd.colorscheme, theme)
      end
    end
  end,
})
