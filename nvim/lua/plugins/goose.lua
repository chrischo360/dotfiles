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
	end
}
