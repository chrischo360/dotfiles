return {
	"catppuccin/nvim",
	name = "catppuccin",
	priority = 1000,
	opts = {
		flavour = "mocha", -- latte, frappe, macchiato, mocha
		transparent_background = true, -- Enable transparency
		integrations = {
			cmp = true,
			gitsigns = true,
			neotree = true,
			telescope = true,
			notify = true,
			mini = true,
		},
	},
	config = function()
		require("catppuccin").setup({
			flavour = "mocha",
			transparent_background = true,
			integrations = {
				cmp = true,
				gitsigns = true,
				neotree = true,
				telescope = true,
				notify = true,
				mini = true,
			},
		})
		-- Load the colorscheme
		vim.cmd.colorscheme "catppuccin"
	end,
}
