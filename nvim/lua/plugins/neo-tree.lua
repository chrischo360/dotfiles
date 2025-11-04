return {
	"nvim-neo-tree/neo-tree.nvim",
	branch = "v3.x",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-tree/nvim-web-devicons", -- not strictly required, but recommended
		"MunifTanjim/nui.nvim",
		"3rd/image.nvim", -- Optional image support in preview window: See `# Preview Mode` for more information
	},
	keys = {
		{
			"<leader>e",
			function()
				require("neo-tree.command").execute({ toggle = true })
			end,
			desc = "Toggle Explorer",
		},
		-- Add a keymap to reveal current file
		{
			"<leader>o",
			function()
				require("neo-tree.command").execute({ action = "focus", reveal = true })
			end,
			desc = "Focus file in Explorer",
		},
	},
	config = function()
		require("neo-tree").setup({
			-- Auto-reveal configuration
			filesystem = {
				filtered_items = {
					visible = true, -- Show hidden files by default
					hide_dotfiles = false,
					hide_gitignored = false,
					hide_hidden = false, -- Windows hidden attribute
				},
				follow_current_file = {
					enabled = true, -- This will find and focus the file in the tree
					leave_dirs_open = true, -- Keep directories open when navigating
				},
				hijack_netrw_behavior = "open_current", -- Open neo-tree when opening a directory
			},

			window = {
				mappings = {
					["<C-h>"] = function() vim.cmd("wincmd h") end,
					["<C-l>"] = function() vim.cmd("wincmd l") end,
				}
			},
		})

		-- Keep these window movement keymaps
		vim.keymap.set('n', '<C-h>', '<C-w>h', { noremap = true, silent = true })
		vim.keymap.set('n', '<C-l>', '<C-w>l', { noremap = true, silent = true })
	end
}
