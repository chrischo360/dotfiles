return {
	"nvim-neo-tree/neo-tree.nvim",
	branch = "v3.x",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-tree/nvim-web-devicons", -- not strictly required, but recommended
		"MunifTanjim/nui.nvim",
		-- "3rd/image.nvim", -- Optional image support in preview window: See `# Preview Mode` for more information
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

			-- Enhanced event handlers to avoid conflicts with session restoration
			event_handlers = {
				{
					event = "neo_tree_buffer_enter",
					handler = function()
						-- Only auto-reveal if not during session restoration
						-- Check if we're in the middle of session loading
						local session_loading = vim.g.persisted_loading_session
						if not session_loading then
							vim.defer_fn(function()
								if vim.bo.filetype ~= "" and vim.fn.expand("%") ~= "" then
									pcall(vim.cmd, "Neotree reveal")
								end
							end, 100)
						end
					end
				},
				{
					-- Handle session restoration better
					event = "neo_tree_window_after_open",
					handler = function()
						-- Ensure proper buffer handling after window opens
						vim.defer_fn(function()
							-- Force refresh to avoid stale buffer issues
							pcall(vim.cmd, "Neotree refresh")
						end, 50)
					end
				},
				{
					-- Prevent buffer conflicts during session loading
					event = "neo_tree_before_render",
					handler = function()
						-- Clear any orphaned buffers that might conflict
						local current_buf = vim.api.nvim_get_current_buf()
						local buf_name = vim.api.nvim_buf_get_name(current_buf)
						
						-- If this is a conflicting buffer, try to resolve it
						if buf_name:match("neo%-tree") and not buf_name:match("neo%-tree filesystem") then
							pcall(function()
								-- Create a new proper buffer if needed
								vim.api.nvim_buf_set_name(current_buf, "neo-tree filesystem [" .. current_buf .. "]")
							end)
						end
					end
				},
				{
					-- Additional safety: clean up any duplicate neo-tree buffers
					event = "neo_tree_window_before_open",
					handler = function()
						-- Clean up any existing neo-tree buffers that might cause conflicts
						for _, buf in ipairs(vim.api.nvim_list_bufs()) do
							if vim.api.nvim_buf_is_valid(buf) then
								local buf_name = vim.api.nvim_buf_get_name(buf)
								local buf_filetype = vim.api.nvim_buf_get_option(buf, "filetype")
								
								-- Delete any existing neo-tree buffers before creating new ones
								if (buf_name:match("neo%-tree") or buf_filetype == "neo-tree") and
								   buf ~= vim.api.nvim_get_current_buf() then
									pcall(vim.api.nvim_buf_delete, buf, { force = true })
								end
							end
						end
					end
				}
			}
		})

		-- Keep these window movement keymaps
		vim.keymap.set('n', '<C-h>', '<C-w>h', { noremap = true, silent = true })
		vim.keymap.set('n', '<C-l>', '<C-w>l', { noremap = true, silent = true })
	end
}
