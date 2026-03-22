return {
	"m4xshen/hardtime.nvim",
	dependencies = { "MunifTanjim/nui.nvim", "nvim-lua/plenary.nvim" },
	event = { "BufReadPre", "BufNewFile" },
	opts = {
		-- Maximum number of repetitions allowed (default: 3)
		max_count = 3,
		-- Enable mouse support
		disable_mouse = false,
		-- Show hints for better commands
		hint = true,
		-- Show notifications when hitting limits
		notification = true,
		-- Notification timeout in milliseconds
		timeout = 2000,
		-- Filetypes to disable hardtime
		disabled_filetypes = {
			"qf",
			"netrw",
			"neo-tree",
			"lazy",
			"mason",
			"oil",
			"TelescopePrompt",
		},
	},
}
