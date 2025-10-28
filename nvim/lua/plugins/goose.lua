return {
	"azorng/goose.nvim",
	lazy = false, -- Load immediately since we want global keymaps
	dependencies = {
		"nvim-lua/plenary.nvim",
		{
			"MeanderingProgrammer/render-markdown.nvim",
			opts = {
				anti_conceal = { enabled = false },
			},
		}
	},
	keys = {
		-- Core functionality
		{ "<leader>gg",  "<cmd>Goose<cr>",                                     desc = "Toggle Goose" },
		{ "<leader>gi",  "<cmd>GooseOpenInput<cr>",                            desc = "Open Goose Input" },
		{ "<leader>gI",  "<cmd>GooseOpenInputNewSession<cr>",                  desc = "Open Goose Input (New Session)" },
		{ "<leader>go",  "<cmd>GooseOpenOutput<cr>",                           desc = "Open Goose Output" },
		{ "<leader>gq",  "<cmd>GooseClose<cr>",                                desc = "Close Goose" },

		-- Session management
		-- { "<leader>gs",  "<cmd>GooseSelectSession<cr>",                        desc = "Select Goose Session" },
		{ "<leader>gt",  "<cmd>GooseToggleFocus<cr>",                          desc = "Toggle Goose Focus" },
		-- { "<leader>gf",  "<cmd>GooseToggleFullscreen<cr>",                     desc = "Toggle Goose Fullscreen" },

		-- Mode switching
		{ "<leader>gmc", "<cmd>lua require('goose.api').set_mode('chat')<cr>", desc = "Set Chat Mode" },
		{ "<leader>gma", "<cmd>lua require('goose.api').set_mode('auto')<cr>", desc = "Set Auto Mode" },

		-- Provider configuration
		{ "<leader>gp",  "<cmd>GooseConfigureProvider<cr>",                    desc = "Configure Provider" },

		-- Diff functionality
		{ "<leader>gd",  "<cmd>GooseDiff<cr>",                                 desc = "Open Goose Diff" },
		{ "<leader>g]",  "<cmd>GooseDiffNext<cr>",                             desc = "Next Diff" },
		{ "<leader>g[",  "<cmd>GooseDiffPrev<cr>",                             desc = "Previous Diff" },
		{ "<leader>gc",  "<cmd>GooseDiffClose<cr>",                            desc = "Close Diff" },
		{ "<leader>gra", "<cmd>GooseRevertAll<cr>",                            desc = "Revert All Changes" },
		{ "<leader>grt", "<cmd>GooseRevertThis<cr>",                           desc = "Revert This File" },

	},
	config = function()
		require("goose").setup({
			-- Use telescope as the preferred picker since it's already configured
			prefered_picker = "telescope",

			-- Keep default global keymaps enabled
			default_global_keymaps = true,

			-- UI Configuration optimized for your setup
			ui = {
				window_width = 0.35, -- 35% of editor width
				input_height = 0.15, -- 15% of window height
				fullscreen = false, -- Start in normal mode
				layout = "right", -- Right-side layout
				floating_height = 0.8, -- 80% height for center layout
				display_model = true, -- Show model name
				display_goose_mode = true -- Show mode (auto/chat)
			},

			-- Provider configuration - customize based on your needs
			providers = {
				gcp_vertex_ai = {
					"gemini-2.5-flash",
					"gemini-2.5-pro",
					"claude-sonnet-4@20250514",
					"claude-opus-4-1@20250805",
				},
				-- Example providers - uncomment and modify as needed
				-- anthropic = {
				--   "claude-3-5-sonnet-20241022",
				--   "claude-3-5-haiku-20241022",
				-- },
				-- openai = {
				--   "gpt-4o",
				--   "gpt-4o-mini",
				-- },
				-- Add other providers as needed
			}
		})

		-- Chat completion notification system
		local notification_config = {
			enabled = true,
			sound = true, -- System sound
			sound_type = "glass", -- glass, blow, bottle, frog, funk, hero, morse, ping, pop, purr, sosumi, submarine, tink
			desktop_notification = true, -- System desktop notification
			show_time = true, -- Show completion time
			show_session = true, -- Show session name in notification
			-- Notification styles: "default", "success", "info", "warn", "error"
			style = "success",
		}

		-- Track chat start times for duration calculation
		local chat_sessions = {}

		-- Simple and reliable notification function
		local function notify_chat_completion(session_name, duration)
			if not notification_config.enabled then return end

			local title = "🪿 Goose AI"
			local message = "Chat completed"

			-- Get current directory/repository info
			local cwd = vim.fn.getcwd()
			local repo_name = vim.fn.fnamemodify(cwd, ":t") -- Get directory name
			local git_branch = vim.fn.system("git branch --show-current 2>/dev/null"):gsub("\n", "")
			if git_branch == "" then git_branch = nil end

			-- Get current file info if in a file
			local current_file = vim.fn.expand("%:t")
			if current_file == "" then current_file = nil end

			-- Build detailed message with context
			local details = {}

			-- Repository/directory context
			if git_branch then
				table.insert(details, "📂 " .. repo_name .. " (" .. git_branch .. ")")
			else
				table.insert(details, "📂 " .. repo_name)
			end

			-- Session context
			if notification_config.show_session and session_name then
				table.insert(details, "💬 " .. session_name)
			end

			-- Current file context
			if current_file then
				table.insert(details, "📄 " .. current_file)
			end

			-- Time context
			if notification_config.show_time and duration then
				table.insert(details, "⏱️ " .. string.format("%.1fs", duration))
			end

			-- Create different message formats for different uses
			local short_message = message
			if notification_config.show_session and session_name then
				short_message = short_message .. " (" .. session_name .. ")"
			end
			if notification_config.show_time and duration then
				short_message = short_message .. " • " .. string.format("%.1fs", duration)
			end

			local detailed_message = message .. "\n" .. table.concat(details, "\n")
			local terminal_message = message .. " - " .. table.concat(details, " | ")

			-- Always play sound first (most reliable)
			if notification_config.sound then
				local sound_file = "/System/Library/Sounds/" ..
				    string.upper(notification_config.sound_type:sub(1, 1)) ..
				    notification_config.sound_type:sub(2) .. ".aiff"
				-- Play sound multiple times for louder notification
				for i = 1, 3 do
					vim.fn.system("afplay '" .. sound_file .. "' &")
					if i < 3 then
						vim.defer_fn(function() end, 200) -- Small delay between sounds
					end
				end
			end

			-- Desktop notification using terminal-notifier
			if notification_config.desktop_notification then
				if vim.fn.executable('terminal-notifier') == 1 then
					local sound_name = notification_config.sound and
					    string.upper(notification_config.sound_type:sub(1, 1)) ..
					    notification_config.sound_type:sub(2) or "Glass"

					-- Use subtitle for repository info and message for details
					local tn_cmd = string.format(
						'terminal-notifier -title "%s" -subtitle "%s" -message "%s" -sound "%s"',
						title,
						git_branch and (repo_name .. " (" .. git_branch .. ")") or repo_name,
						table.concat(details, " • "),
						sound_name
					)
					print("Sending notification: " .. tn_cmd)
					vim.fn.system(tn_cmd .. " &")
				else
					-- Fallback to simple osascript
					local cmd = string.format(
						'osascript -e "display notification \\"%s\\" with title \\"%s\\""',
						terminal_message, title
					)
					print("Fallback notification: " .. cmd)
					vim.fn.system(cmd .. " &")
				end
			end

			-- Enhanced Neovim notification with more context
			local neovim_title = "Goose Chat Complete!"
			if git_branch then
				neovim_title = neovim_title .. " (" .. repo_name .. "/" .. git_branch .. ")"
			else
				neovim_title = neovim_title .. " (" .. repo_name .. ")"
			end

			vim.notify("🎉 " .. short_message, vim.log.levels.INFO, {
				title = neovim_title,
				timeout = 10000, -- Longer timeout for more info
			})

			-- Print detailed colored notification to terminal
			local colored_header = string.format('\027[1;32m🎉 %s\027[0m', title)
			local colored_details = {}
			for _, detail in ipairs(details) do
				table.insert(colored_details, '\027[36m' .. detail .. '\027[0m')
			end

			local full_terminal_message = colored_header .. '\n' ..
			    table.concat(colored_details, '\n') .. '\n' ..
			    '\027[90m' .. cwd .. '\027[0m\n'

			io.write(full_terminal_message)
			io.flush()
		end

		-- Wrap the original goose job execution to add notifications
		local function setup_chat_notifications()
			local job_module = require('goose.job')
			local state = require('goose.state')

			-- Store original execute function
			local original_execute = job_module.execute

			-- Override execute function with notification support
			job_module.execute = function(prompt, handlers)
				-- Record start time
				local start_time = vim.uv.hrtime()
				local session_name = state.active_session and state.active_session.name or
				state.new_session_name

				-- Wrap the original handlers
				local enhanced_handlers = vim.tbl_deep_extend("force", handlers, {
					on_exit = function()
						-- Calculate duration
						local duration = (vim.uv.hrtime() - start_time) / 1e9

						-- Call original on_exit handler first
						if handlers.on_exit then
							handlers.on_exit()
						end

						-- Add our notification
						vim.schedule(function()
							notify_chat_completion(session_name, duration)
						end)
					end
				})

				-- Call original execute with enhanced handlers
				return original_execute(prompt, enhanced_handlers)
			end
		end

		-- Initialize notification system
		setup_chat_notifications()

		-- Optional: Create additional commands for convenience
		vim.api.nvim_create_user_command('GooseRun', function(opts)
			require('goose.api').run(opts.args)
		end, {
			nargs = '*',
			desc = 'Run Goose with prompt (continue session)'
		})

		vim.api.nvim_create_user_command('GooseRunNew', function(opts)
			require('goose.api').run_new_session(opts.args)
		end, {
			nargs = '*',
			desc = 'Run Goose with prompt (new session)'
		})

		-- Command to toggle notifications
		vim.api.nvim_create_user_command('GooseToggleNotifications', function()
			notification_config.enabled = not notification_config.enabled
			vim.notify("Goose notifications " .. (notification_config.enabled and "enabled" or "disabled"))
		end, {
			desc = 'Toggle Goose completion notifications'
		})

		-- Command to configure notifications
		vim.api.nvim_create_user_command('GooseConfigureNotifications', function()
			local options = {
				"Toggle notifications: " .. (notification_config.enabled and "ON" or "OFF"),
				"Toggle desktop notification: " ..
				(notification_config.desktop_notification and "ON" or "OFF"),
				"Toggle sound: " .. (notification_config.sound and "ON" or "OFF"),
				"Sound type: " .. notification_config.sound_type,
				"Toggle time display: " .. (notification_config.show_time and "ON" or "OFF"),
				"Toggle session display: " .. (notification_config.show_session and "ON" or "OFF"),
				"Style: " .. notification_config.style,
			}

			vim.ui.select(options, {
				prompt = "Configure Goose Notifications:",
			}, function(choice)
				if not choice then return end

				if choice:match("Toggle notifications:") then
					notification_config.enabled = not notification_config.enabled
					vim.notify("Notifications " ..
					(notification_config.enabled and "enabled" or "disabled"))
				elseif choice:match("Toggle desktop notification:") then
					notification_config.desktop_notification = not notification_config
					.desktop_notification
					vim.notify("Desktop notifications " ..
					(notification_config.desktop_notification and "enabled" or "disabled"))
				elseif choice:match("Toggle sound:") then
					notification_config.sound = not notification_config.sound
					vim.notify("Sound " .. (notification_config.sound and "enabled" or "disabled"))
				elseif choice:match("Sound type:") then
					local sounds = { "glass", "blow", "bottle", "frog", "funk", "hero", "morse",
						"ping", "pop", "purr", "sosumi", "submarine", "tink" }
					vim.ui.select(sounds, {
						prompt = "Select sound type (louder sounds: hero, funk, sosumi):",
					}, function(sound)
						if sound then
							notification_config.sound_type = sound
							vim.notify("Sound changed to: " .. sound)
							-- Test the sound
							if notification_config.sound then
								if notification_config.desktop_notification then
									vim.fn.system(string.format(
									'osascript -e \'display notification "Test sound" with title "Goose" sound name "%s"\' &',
										sound))
								else
									local sound_file = "/System/Library/Sounds/" ..
									    string.upper(sound:sub(1, 1)) ..
									    sound:sub(2) .. ".aiff"
									vim.fn.system("afplay '" .. sound_file .. "' &")
								end
							end
						end
					end)
				elseif choice:match("Toggle time display:") then
					notification_config.show_time = not notification_config.show_time
					vim.notify("Time display " ..
					(notification_config.show_time and "enabled" or "disabled"))
				elseif choice:match("Toggle session display:") then
					notification_config.show_session = not notification_config.show_session
					vim.notify("Session display " ..
					(notification_config.show_session and "enabled" or "disabled"))
				elseif choice:match("Style:") then
					local styles = { "default", "success", "info", "warn", "error" }
					vim.ui.select(styles, {
						prompt = "Select notification style:",
					}, function(style)
						if style then
							notification_config.style = style
							vim.notify("Notification style changed to: " .. style)
						end
					end)
				end
			end)
		end, {
			desc = 'Configure Goose notification settings'
		})

		-- Command to test notifications
		vim.api.nvim_create_user_command('GooseTestNotification', function()
			notify_chat_completion("test-session", 5.2)
		end, {
			desc = 'Test Goose notification with sample data'
		})

		-- Command to debug notification issues
		vim.api.nvim_create_user_command('GooseDebugNotifications', function()
			print("=== Goose Notification Debug ===")
			print("notification_config.enabled: " .. tostring(notification_config.enabled))
			print("notification_config.desktop_notification: " ..
			tostring(notification_config.desktop_notification))
			print("notification_config.sound: " .. tostring(notification_config.sound))
			print("notification_config.sound_type: " .. notification_config.sound_type)

			-- Test osascript directly
			print("\n--- Testing osascript ---")
			local cmd =
			'osascript -e "display notification \\"Direct osascript test\\" with title \\"Debug Test\\""'
			print("Command: " .. cmd)
			local result = vim.fn.system(cmd)
			print("Result: " .. (result or "nil"))

			-- Test terminal-notifier if available
			if vim.fn.executable('terminal-notifier') == 1 then
				print("\n--- Testing terminal-notifier ---")
				local tn_cmd = 'terminal-notifier -title "Debug Test" -message "Terminal notifier test"'
				print("Command: " .. tn_cmd)
				vim.fn.system(tn_cmd .. " &")
			else
				print("\n--- terminal-notifier not available ---")
			end

			-- Test the actual notification function
			print("\n--- Testing notification function ---")
			notify_chat_completion("debug-session", 1.5)
		end, {
			desc = 'Debug Goose notification issues'
		})
	end
}
