return {
	"olimorris/onedarkpro.nvim",
	priority = 1000,
	opts = {
		options = {
			transparency = false,
			terminal_colors = true,
			lualine_transparency = false,
			highlight_inactive_windows = false,
		},
		styles = {
			comments = "italic",
			keywords = "bold",
			functions = "NONE",
			variables = "NONE",
		},
	},
	config = function(_, opts)
		require("onedarkpro").setup(opts)
	end,
}
