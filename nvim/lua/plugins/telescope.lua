return {
	"nvim-telescope/telescope.nvim",
	tag = "0.1.8", -- Use the latest stable release
	dependencies = {
		"nvim-lua/plenary.nvim",
		{ "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
		{
			"nvim-telescope/telescope-frecency.nvim",
			dependencies = { "kkharji/sqlite.lua" },
		},
	},
	cmd = { "Telescope" },
	keys = {
		{ "<leader>ff", "<cmd>Telescope find_files<cr>", desc = "Find Files" },
		{ "<leader>fg", "<cmd>Telescope live_grep<cr>", desc = "Live Grep" },
		{ "<leader>fb", "<cmd>Telescope buffers<cr>", desc = "Buffers" },
		{ "<leader>fF", "<cmd>Telescope frecency workspace=CWD<cr>", desc = "Find Files (Smart)" },
		{ "<leader>fh", "<cmd>Telescope help_tags<cr>", desc = "Help Tags" },
		{ "<leader>fr", "<cmd>Telescope oldfiles<cr>", desc = "Recent Files" },
		-- Git telescopes
		{ "<leader>gc", "<cmd>Telescope git_commits<cr>", desc = "Git Commits" },
		{ "<leader>gC", "<cmd>Telescope git_bcommits<cr>", desc = "Git Buffer Commits" },
		{ "<leader>gB", "<cmd>Telescope git_branches<cr>", desc = "Git Branches" },
		{ "<leader>gS", "<cmd>Telescope git_status<cr>", desc = "Git Status" },
		-- { "<leader>gf", "<cmd>Telescope git_files<cr>",              desc = "Git Files" },
	},
	config = function()
		local telescope = require("telescope")
		local actions = require("telescope.actions")

		telescope.setup({
			defaults = {
				path_display = { "smart" },
				dynamic_preview_title = true,

				-- Performance optimizations
				cache_picker = {
					num_pickers = 5, -- Cache recent pickers
				},

				-- Faster file operations
				file_sorter = require("telescope.sorters").get_fuzzy_file,
				generic_sorter = require("telescope.sorters").get_generic_fuzzy_sorter,

				-- Better preview handling
				preview = {
					filesize_limit = 0.1, -- 100KB limit for preview
					timeout = 250, -- Faster preview timeout
				},

				file_ignore_patterns = {
					"node_modules",
					".git/",
					"%.lock",
					"__pycache__",
					"%.sqlite3",
					"%.ipynb",
					"vendor/*",
					"%.jpg",
					"%.jpeg",
					"%.png",
					"%.svg",
					"%.otf",
					"%.ttf",
					-- Add large file patterns for better performance
					"%.zip",
					"%.tar.gz",
					"%.mp4",
					"%.mkv",
					"%.pdf",
				},
				vimgrep_arguments = {
					"rg",
					"--color=never",
					"--no-heading",
					"--with-filename",
					"--line-number",
					"--column",
					"--smart-case",
					"--hidden",
					"--glob=!.git/",
				},
				mappings = {
					i = {
						["<C-k>"] = actions.move_selection_previous,
						["<C-j>"] = actions.move_selection_next,
						["<C-q>"] = actions.send_to_qflist + actions.open_qflist,
						["<C-c>"] = actions.close,
					},
					n = {
						["q"] = actions.close,
						["<C-q>"] = actions.send_to_qflist + actions.open_qflist,
					},
				},
			},
			pickers = {
				find_files = {
					hidden = true,
					-- Enable fd for faster file finding
					find_command = { "fd", "--type", "f", "--strip-cwd-prefix" },
				},
				live_grep = {
					-- Optimize live grep
					additional_args = function()
						return { "--hidden", "--smart-case" }
					end,
				},
				buffers = {
					show_all_buffers = true,
					sort_lastused = true,
					mappings = {
						i = {
							["<c-d>"] = actions.delete_buffer,
						},
					},
				},
			},
			extensions = {
				fzf = {
					fuzzy = true,
					override_generic_sorter = true,
					override_file_sorter = true,
					case_mode = "smart_case",
				},
				frecency = {
					show_scores = false,
					show_unindexed = true, -- This includes ALL files, not just cached ones
					ignore_patterns = {
						"*.git/*",
						"*/tmp/*",
						"*/node_modules/*",
						"*/.DS_Store",
						"*/build/*",
						"*/dist/*",
						"*/__pycache__/*",
					},
					disable_devicons = false,
					workspaces = {
						["conf"] = "/Users/cc446g/dotfiles",
						["codebase"] = "/Users/cc446g/codebase",
						["repos"] = "/Users/cc446g/devbox_repos",
					},
					-- Enhanced frecency settings
					max_timestamps = 10, -- Keep more history
					auto_validate = true, -- Auto-cleanup invalid entries
					db_safe_mode = false, -- Better performance
				},
			},
		})

		-- Load extensions with error handling
		pcall(telescope.load_extension, "fzf")
		pcall(telescope.load_extension, "frecency")
	end,
}
