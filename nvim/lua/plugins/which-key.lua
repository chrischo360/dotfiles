return {
	"folke/which-key.nvim",
	event = "VeryLazy",
	config = function()
		local wk = require("which-key")

		-- Setup which-key
		wk.setup({
			-- your configuration comes here
			-- or leave it empty to use the default settings
		})

		-- Register Claude keybindings with organized groups
		wk.add({
			{ "<leader>c", group = "🤖 Claude AI" },
			-- The new keymap for claude-code.nvim
		})

		-- Register Harpoon keybindings with organized groups
		wk.add({
			{ "<leader>h", group = "🎯 Harpoon" },
			{ "<leader>ha", desc = "Add file" },
			{ "<leader>hh", desc = "Toggle menu" },
			{ "<leader>h1", desc = "Go to file 1" },
			{ "<leader>h2", desc = "Go to file 2" },
			{ "<leader>h3", desc = "Go to file 3" },
			{ "<leader>h4", desc = "Go to file 4" },
			{ "<leader>hn", desc = "Next file" },
			{ "<leader>hp", desc = "Previous file" },
			{ "<leader>hd", desc = "Remove file" },
			{ "<leader>hc", desc = "Clear all" },
			{ "<leader>ht", desc = "Telescope menu" },
			-- Alt-based navigation
			{ "<M-h>", desc = "Harpoon: File 1" },
			{ "<M-j>", desc = "Harpoon: File 2" },
			{ "<M-k>", desc = "Harpoon: File 3" },
			{ "<M-l>", desc = "Harpoon: File 4" },
		})
	end,
	keys = {
		{
			"<leader>?",
			function()
				require("which-key").show({ global = false })
			end,
			desc = "Buffer Local Keymaps (which-key)",
		},
	},
}
