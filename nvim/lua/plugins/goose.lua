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
		{ "<leader>gs",  "<cmd>GooseSelectSession<cr>",                        desc = "Select Goose Session" },
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
			sound = true, -- macOS system sound
			show_time = true, -- Show completion time
			show_session = true, -- Show session name in notification
			-- Notification styles: "default", "success", "info", "warn", "error"
			style = "success",
		}

		-- Track chat start times for duration calculation
		local chat_sessions = {}

		-- Enhanced notification function
		local function notify_chat_completion(session_name, duration)
			if not notification_config.enabled then return end

			local message = "🎉 Goose chat completed"
			
			if notification_config.show_session and session_name then
				message = message .. " (" .. session_name .. ")"
			end
			
			if notification_config.show_time and duration then
				message = message .. " • " .. string.format("%.1fs", duration)
			end

			-- Show Neovim notification
			local level = vim.log.levels.INFO
			if notification_config.style == "success" then
				level = vim.log.levels.INFO
			elseif notification_config.style == "warn" then
				level = vim.log.levels.WARN
			elseif notification_config.style == "error" then
				level = vim.log.levels.ERROR
			end

			vim.notify(message, level, {
				title = "Goose",
				timeout = 3000,
			})

			-- Play system sound on macOS
			if notification_config.sound then
				vim.fn.system("afplay /System/Library/Sounds/Glass.aiff &")
			end
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
				local session_name = state.active_session and state.active_session.name or state.new_session_name
				
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
				"Toggle sound: " .. (notification_config.sound and "ON" or "OFF"),
				"Toggle time display: " .. (notification_config.show_time and "ON" or "OFF"),
				"Toggle session display: " .. (notification_config.show_session and "ON" or "OFF"),
				"Style: " .. notification_config.style,
			}
			
			vim.ui.select(options, {
				prompt = "Configure Goose Notifications:",
			}, function(choice)
				if not choice then return end
				
				if choice:match("Toggle notifications") then
					notification_config.enabled = not notification_config.enabled
				elseif choice:match("Toggle sound") then
					notification_config.sound = not notification_config.sound
				elseif choice:match("Toggle time display") then
					notification_config.show_time = not notification_config.show_time
				elseif choice:match("Toggle session display") then
					notification_config.show_session = not notification_config.show_session
				elseif choice:match("Style") then
					local styles = {"default", "success", "info", "warn", "error"}
					vim.ui.select(styles, {
						prompt = "Select notification style:",
					}, function(style)
						if style then
							notification_config.style = style
						end
					end)
				end
				
				vim.notify("Notification settings updated!")
			end)
		end, {
			desc = 'Configure Goose notification settings'
		})
	end
}
