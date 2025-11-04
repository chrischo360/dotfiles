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

			code_blocks = {
				enable = true,
				style = "language",
			},

			markdown = {
				headings = {
					enable = true,
					heading_1 = { style = "icon", icon = "󰼏  " },
					heading_2 = { style = "icon", icon = "󰼐  " },
					heading_3 = { style = "icon", icon = "󰼑  " },
					heading_4 = { style = "icon", icon = "󰼒  " },
					heading_5 = { style = "icon", icon = "󰼓  " },
					heading_6 = { style = "icon", icon = "󰼔  " },
				},
				inline_codes = {
					enable = true,
				},
				links = {
					enable = true,
				},
				list_items = {
					enable = true,
				},
				checkboxes = {
					enable = true,
				},
			},
		})
	end,
	keys = {
		{ "<leader>mp", "<cmd>Markview toggleAll<cr>", desc = "Toggle Markdown Preview" },
	},
}
