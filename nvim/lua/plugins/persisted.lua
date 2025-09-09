-- Lua
return {
	"olimorris/persisted.nvim",
	lazy = false, -- Load immediately
	priority = 1000, -- Load early
	config = function()
		require("persisted").setup({
			autostart = true, -- Automatically start the plugin on load
			autoload = true, -- Automatically load the session for the cwd on Neovim startup
			autosave = true, -- Automatically save the session on exit
			follow_cwd = true, -- Change the session file to match any change in the cwd

			-- Function to determine if a session should be saved
			should_save = function()
				-- Only save if we have real buffers open (not just empty or help buffers)
				if vim.fn.argc() > 0 then
					return true -- Always save if files were passed as arguments
				end

				local bufs = vim.api.nvim_list_bufs()
				for _, buf in ipairs(bufs) do
					if vim.api.nvim_buf_is_loaded(buf) and vim.api.nvim_buf_get_option(buf, "buflisted") then
						local buftype = vim.api.nvim_buf_get_option(buf, "buftype")
						local bufname = vim.api.nvim_buf_get_name(buf)
						local filetype = vim.api.nvim_buf_get_option(buf, "filetype")
						
						-- Skip Neo-tree and other special buffers
						if bufname:match("neo%-tree") or bufname:match("Neo%-tree") or 
						   filetype == "neo-tree" or buftype ~= "" then
							-- Skip this buffer
						elseif buftype == "" then -- Normal file buffer
							return true
						end
					end
				end
				return false
			end,

			save_dir = vim.fn.expand(vim.fn.stdpath("data") .. "/sessions/"), -- Directory where session files are saved
			use_git_branch = false,                      -- Don't include git branch in session file name

			-- Function to run when `autoload = true` but there is no session to load
			on_autoload_no_session = function()
				vim.notify("No session found for " .. vim.fn.getcwd(), vim.log.levels.WARN)
			end,

			-- Pre-save hook to clean up before saving
			pre_save = function()
				-- Close NeoTree if it's open
				pcall(vim.cmd, "Neotree close")
				-- Close any floating windows
				for _, win in ipairs(vim.api.nvim_list_wins()) do
					if vim.api.nvim_win_get_config(win).relative ~= "" then
						pcall(vim.api.nvim_win_close, win, false)
					end
				end
			end,

			-- Post-save notification
			post_save = function()
				vim.notify("Session saved!", vim.log.levels.INFO)
			end,

			-- Post-load notification and cleanup
			post_load = function()
				-- Clean up any duplicate or problematic buffers after session load
				vim.defer_fn(function()
					-- Close any Neo-tree buffers that might have been restored improperly
					for _, buf in ipairs(vim.api.nvim_list_bufs()) do
						if vim.api.nvim_buf_is_valid(buf) then
							local buf_name = vim.api.nvim_buf_get_name(buf)
							local buf_filetype = vim.api.nvim_buf_get_option(buf, "filetype")
							-- Check for various Neo-tree buffer patterns
							if buf_name:match("neo%-tree") or buf_name:match("Neo%-tree") or 
							   buf_name:match("filesystem") or buf_filetype == "neo-tree" then
								pcall(vim.api.nvim_buf_delete, buf, { force = true })
							end
						end
					end
					-- Force refresh of any open Neo-tree windows after cleanup
					pcall(vim.cmd, "Neotree refresh")
				end, 200)
				vim.notify("Session loaded!", vim.log.levels.INFO)
			end,

			allowed_dirs = { "~/codebase", "~/dotfiles" }, -- Table of dirs that the plugin will start and autoload from
			ignored_dirs = {},        -- Table of dirs that are ignored for starting and autoloading

			telescope = {
				mappings = { -- Mappings for managing sessions in Telescope
					copy_session = "<C-c>",
					change_branch = "<C-b>",
					delete_session = "<C-d>",
				},
				icons = { -- icons displayed in the Telescope picker
					selected = " ",
					dir = "  ",
					branch = " ",
				},
			},
		})
	end,
	keys = {
		{ "<leader>ql", function() require("persisted").load() end,   desc = "Load session" },
		{ "<leader>qs", function() require("persisted").save() end,   desc = "Save session" },
		{ "<leader>qd", function() require("persisted").stop() end,   desc = "Stop session" },
		{ "<leader>qr", function() require("persisted").delete() end, desc = "Delete session" },
		{ "<leader>qt", function() require("persisted").toggle() end, desc = "Toggle session" },
		{ "<leader>qf", "<cmd>Telescope persisted<cr>",               desc = "Find sessions" },
		{
			"<leader>qc",
			function()
				local sessions_dir = vim.fn.stdpath("data") .. "/sessions/"
				local sessions = vim.fn.glob(sessions_dir .. "*.vim", true, true)
				if #sessions > 0 then
					local choice = vim.fn.confirm("Delete all " .. #sessions .. " sessions?", "&Yes\n&No", 2)
					if choice == 1 then
						for _, session in ipairs(sessions) do
							vim.fn.delete(session)
						end
						vim.notify("Deleted " .. #sessions .. " sessions!", vim.log.levels.INFO)
					end
				else
					vim.notify("No sessions to delete", vim.log.levels.INFO)
				end
			end,
			desc = "Clear all sessions"
		},
		{
			"<leader>qi",
			function()
				local persisted = require("persisted")
				print("Session started:", persisted.session_started)
				print("Current session:", persisted.current_session or "None")
				print("Save dir:", vim.fn.stdpath("data") .. "/sessions/")
			end,
			desc = "Session info"
		},
	},
}
