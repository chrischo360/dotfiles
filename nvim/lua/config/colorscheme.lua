-- Colorscheme Configuration
-- Default theme and theme picker

-- Set default colorscheme
-- Available themes:
--   - kanagawa-wave (dark)
--   - kanagawa-lotus (light)
--   - kanagawa-dragon (darker)
--   - rose-pine (auto detects based on background)
--   - rose-pine-main (dark)
--   - rose-pine-moon (dark, higher contrast)
--   - rose-pine-dawn (light)
--   - onedark (dark)
--   - onedark_vivid (dark, more saturated)
--   - onedark_dark (dark, deeper blacks)
--   - everforest (dark/light based on background setting)
--   - dracula
--   - nord
local default_colorscheme = "dracula-soft"

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
set_colorscheme(default_colorscheme)

-- Keybinding for theme picker (using Telescope)
vim.keymap.set("n", "<leader>th", "<cmd>Telescope colorscheme<cr>", {
	desc = "Theme picker",
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
