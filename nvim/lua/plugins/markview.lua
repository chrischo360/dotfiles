return {
	"OXY2DEV/markview.nvim",
	lazy = false, -- Don't lazy load (markview has internal lazy-loading)
	dependencies = {
		"nvim-treesitter/nvim-treesitter",
	},
	config = function()
		require("markview").setup({
			preview = {
				modes = { "n", "no", "c" }, -- Preview in normal, operator-pending, command modes
				hybrid_modes = { "i" }, -- Edit while previewing in insert mode
				filetypes = { "markdown", "md" },
			},
		})
	end,
	keys = {
		{ "<leader>mp", "<cmd>Markview toggleAll<cr>", desc = "Toggle Markdown Preview" },
	},
}
