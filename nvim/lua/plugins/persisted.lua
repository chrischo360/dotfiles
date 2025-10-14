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
						
						-- Enhanced filtering for Neo-tree and special buffers
						local is_special_buffer = 
							bufname:match("neo%-tree") or 
							bufname:match("Neo%-tree") or 
							bufname:match("filesystem") or
							bufname:match("git_status") or
							bufname:match("buffers") or
							bufname:match("document_symbols") or
							filetype == "neo-tree" or 
							filetype == "neo-tree-popup" or
							buftype ~= "" or
							bufname == "" or
							bufname:match("^term://") or
							bufname:match("^oil://")
						
						if not is_special_buffer and buftype == "" then
							return true -- Found a real file buffer
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
				-- Set flag to indicate we're saving a session
				vim.g.persisted_saving_session = true
				
				-- Close NeoTree if it's open
				pcall(vim.cmd, "Neotree close")
				
				-- Force delete any neo-tree buffers before saving
				for _, buf in ipairs(vim.api.nvim_list_bufs()) do
					if vim.api.nvim_buf_is_valid(buf) then
						local buf_name = vim.api.nvim_buf_get_name(buf)
						local buf_filetype = vim.api.nvim_buf_get_option(buf, "filetype")
						if buf_name:match("neo%-tree") or buf_filetype == "neo-tree" then
							pcall(vim.api.nvim_buf_delete, buf, { force = true })
						end
					end
				end
				
				-- Close any floating windows
				for _, win in ipairs(vim.api.nvim_list_wins()) do
					if vim.api.nvim_win_get_config(win).relative ~= "" then
						pcall(vim.api.nvim_win_close, win, false)
					end
				end
				
				-- Small delay to ensure everything is closed
				vim.defer_fn(function()
					vim.g.persisted_saving_session = false
				end, 100)
			end,

			-- Post-save hook with session file cleanup
			post_save = function()
				vim.g.persisted_saving_session = false
				
				-- Clean the session file after it's saved to remove any neo-tree references
				local persisted = require("persisted")
				local session_file = persisted.current_session
				
				if session_file and vim.fn.filereadable(session_file) == 1 then
					vim.defer_fn(function()
						local lines = vim.fn.readfile(session_file)
						local cleaned_lines = {}
						local removed_count = 0
						
						for _, line in ipairs(lines) do
							-- Skip lines that reference neo-tree (comprehensive patterns)
							if not (line:match("neo%-tree") or line:match("Neo%-tree") or 
								   line:match("filesystem %[%d+%]") or line:match("neo%-tree\\")) then
								table.insert(cleaned_lines, line)
							else
								removed_count = removed_count + 1
							end
						end
						
						if removed_count > 0 then
							vim.fn.writefile(cleaned_lines, session_file)
							vim.notify("Session saved and cleaned! Removed " .. removed_count .. " neo-tree references.", vim.log.levels.INFO)
						else
							vim.notify("Session saved!", vim.log.levels.INFO)
						end
					end, 50) -- Small delay to ensure session file is fully written
				else
					vim.notify("Session saved!", vim.log.levels.INFO)
				end
			end,

			-- Post-load notification and cleanup
			post_load = function()
				-- Set flag to indicate we're loading a session
				vim.g.persisted_loading_session = true
				
				-- Clean up any duplicate or problematic buffers after session load
				vim.defer_fn(function()
					-- Close any Neo-tree buffers that might have been restored improperly
					for _, buf in ipairs(vim.api.nvim_list_bufs()) do
						if vim.api.nvim_buf_is_valid(buf) then
							local buf_name = vim.api.nvim_buf_get_name(buf)
							local buf_filetype = vim.api.nvim_buf_get_option(buf, "filetype")
							-- Enhanced pattern matching for Neo-tree buffers
							local is_neotree_buffer = 
								buf_name:match("neo%-tree") or 
								buf_name:match("Neo%-tree") or 
								buf_name:match("filesystem") or 
								buf_name:match("git_status") or
								buf_name:match("buffers") or
								buf_name:match("document_symbols") or
								buf_filetype == "neo-tree" or
								buf_filetype == "neo-tree-popup"
								
							if is_neotree_buffer then
								pcall(vim.api.nvim_buf_delete, buf, { force = true })
							end
						end
					end
					
					-- Clear the loading flag after cleanup
					vim.g.persisted_loading_session = false
					
					-- Force refresh of any open Neo-tree windows after cleanup
					pcall(vim.cmd, "Neotree refresh")
				end, 300) -- Increased delay for better stability
				
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
				print("Loading flag:", vim.g.persisted_loading_session or "false")
				print("Saving flag:", vim.g.persisted_saving_session or "false")
			end,
			desc = "Session info"
		},
		{
			"<leader>qb",
			function()
				print("=== Current Buffer Analysis ===")
				local bufs = vim.api.nvim_list_bufs()
				for _, buf in ipairs(bufs) do
					if vim.api.nvim_buf_is_loaded(buf) then
						local bufname = vim.api.nvim_buf_get_name(buf)
						local buftype = vim.api.nvim_buf_get_option(buf, "buftype")
						local filetype = vim.api.nvim_buf_get_option(buf, "filetype")
						local listed = vim.api.nvim_buf_get_option(buf, "buflisted")
						
						-- Check if this would be filtered
						local is_special = 
							bufname:match("neo%-tree") or 
							bufname:match("Neo%-tree") or 
							bufname:match("filesystem") or
							filetype == "neo-tree" or 
							buftype ~= ""
						
						local status = is_special and "🚫 FILTERED" or "✅ INCLUDED"
						print(string.format("Buffer %d: %s [%s] (%s/%s) %s", 
							buf, bufname == "" and "<unnamed>" or bufname, 
							filetype, buftype, listed and "listed" or "unlisted", status))
					end
				end
			end,
			desc = "Debug buffer state"
		},
	},
}
