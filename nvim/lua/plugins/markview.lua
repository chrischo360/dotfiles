return {
	"OXY2DEV/markview.nvim",
	lazy = false, -- Don't lazy load (markview has internal lazy-loading)
	dependencies = {
		"nvim-treesitter/nvim-treesitter",
	},
	config = function()
		-- Define softer, muted Kanagawa-inspired colors for markview
		local kanagawa_colors = {
			-- Softer, more pastel versions
			crystalBlue = "#7E9CD8",
			springViolet1 = "#9CABCA",
			springGreen = "#98BB6C",
			carpYellow = "#C0A36E",
			peachRed = "#E46876",
			lightBlue = "#7FB4CA",
			springBlue = "#7FB4CA",
			boatYellow1 = "#C0A36E",
			waveAqua2 = "#6A9589",
			sakuraPink = "#D27E99",
			oniViolet = "#957FB8",
			waveRed = "#C34043",
			-- Background colors (more subtle)
			sumiInk2 = "#2A2A37",
			sumiInk3 = "#363646",
			sumiInk4 = "#54546D",
		}

		-- Set up custom highlight groups with backgrounds for softer look
		vim.api.nvim_set_hl(0, "MarkviewHeading1", {
			fg = kanagawa_colors.peachRed,
			bg = kanagawa_colors.sumiInk2,
			bold = true
		})
		vim.api.nvim_set_hl(0, "MarkviewHeading2", {
			fg = kanagawa_colors.carpYellow,
			bg = kanagawa_colors.sumiInk2,
			bold = true
		})
		vim.api.nvim_set_hl(0, "MarkviewHeading3", {
			fg = kanagawa_colors.springGreen,
			bg = kanagawa_colors.sumiInk2,
			bold = true
		})
		vim.api.nvim_set_hl(0, "MarkviewHeading4", {
			fg = kanagawa_colors.lightBlue,
			bg = kanagawa_colors.sumiInk2,
			bold = true
		})
		vim.api.nvim_set_hl(0, "MarkviewHeading5", {
			fg = kanagawa_colors.springViolet1,
			bg = kanagawa_colors.sumiInk2,
			bold = true
		})
		vim.api.nvim_set_hl(0, "MarkviewHeading6", {
			fg = kanagawa_colors.oniViolet,
			bg = kanagawa_colors.sumiInk2,
			bold = true
		})

		vim.api.nvim_set_hl(0, "MarkviewCode", {
			fg = kanagawa_colors.boatYellow1,
			bg = kanagawa_colors.sumiInk3
		})
		vim.api.nvim_set_hl(0, "MarkviewCodeBlock", {
			fg = kanagawa_colors.waveAqua2,
			bg = kanagawa_colors.sumiInk2
		})
		vim.api.nvim_set_hl(0, "MarkviewInlineCode", {
			fg = kanagawa_colors.sakuraPink,
			bg = kanagawa_colors.sumiInk3
		})
		vim.api.nvim_set_hl(0, "MarkviewLink", {
			fg = kanagawa_colors.springBlue,
			underline = true
		})
		vim.api.nvim_set_hl(0, "MarkviewBold", { bold = true })
		vim.api.nvim_set_hl(0, "MarkviewItalic", { italic = true })
		vim.api.nvim_set_hl(0, "MarkviewListMarker", {
			fg = kanagawa_colors.oniViolet
		})
		vim.api.nvim_set_hl(0, "MarkviewCheckboxChecked", {
			fg = kanagawa_colors.springGreen,
			bold = true
		})
		vim.api.nvim_set_hl(0, "MarkviewCheckboxUnchecked", {
			fg = kanagawa_colors.sumiInk4
		})

		require("markview").setup({
			preview = {
				modes = { "n", "no", "c" }, -- Preview in normal, operator-pending, command modes
				hybrid_modes = { "i" }, -- Edit while previewing in insert mode
				filetypes = { "markdown", "md" },
			},

			code_blocks = {
				enable = true,
				style = "language",
				border_hl = "MarkviewCodeBlock",
			},

			markdown = {
				headings = {
					enable = true,
					heading_1 = { style = "icon", icon = "󰼏  ", hl = "MarkviewHeading1" },
					heading_2 = { style = "icon", icon = "󰼐  ", hl = "MarkviewHeading2" },
					heading_3 = { style = "icon", icon = "󰼑  ", hl = "MarkviewHeading3" },
					heading_4 = { style = "icon", icon = "󰼒  ", hl = "MarkviewHeading4" },
					heading_5 = { style = "icon", icon = "󰼓  ", hl = "MarkviewHeading5" },
					heading_6 = { style = "icon", icon = "󰼔  ", hl = "MarkviewHeading6" },
				},
				inline_codes = {
					enable = true,
					hl = "MarkviewInlineCode",
				},
				links = {
					enable = true,
					hyperlinks = { hl = "MarkviewLink" },
				},
				list_items = {
					enable = true,
					marker_minus = { hl = "MarkviewListMarker" },
					marker_plus = { hl = "MarkviewListMarker" },
					marker_star = { hl = "MarkviewListMarker" },
				},
				checkboxes = {
					enable = true,
					checked = { hl = "MarkviewCheckboxChecked" },
					unchecked = { hl = "MarkviewCheckboxUnchecked" },
				},
			},
		})

		-- Re-apply colors when colorscheme changes
		vim.api.nvim_create_autocmd("ColorScheme", {
			callback = function()
				vim.api.nvim_set_hl(0, "MarkviewHeading1", {
					fg = kanagawa_colors.peachRed,
					bg = kanagawa_colors.sumiInk2,
					bold = true
				})
				vim.api.nvim_set_hl(0, "MarkviewHeading2", {
					fg = kanagawa_colors.carpYellow,
					bg = kanagawa_colors.sumiInk2,
					bold = true
				})
				vim.api.nvim_set_hl(0, "MarkviewHeading3", {
					fg = kanagawa_colors.springGreen,
					bg = kanagawa_colors.sumiInk2,
					bold = true
				})
				vim.api.nvim_set_hl(0, "MarkviewHeading4", {
					fg = kanagawa_colors.lightBlue,
					bg = kanagawa_colors.sumiInk2,
					bold = true
				})
				vim.api.nvim_set_hl(0, "MarkviewHeading5", {
					fg = kanagawa_colors.springViolet1,
					bg = kanagawa_colors.sumiInk2,
					bold = true
				})
				vim.api.nvim_set_hl(0, "MarkviewHeading6", {
					fg = kanagawa_colors.oniViolet,
					bg = kanagawa_colors.sumiInk2,
					bold = true
				})
				vim.api.nvim_set_hl(0, "MarkviewCode", {
					fg = kanagawa_colors.boatYellow1,
					bg = kanagawa_colors.sumiInk3
				})
				vim.api.nvim_set_hl(0, "MarkviewCodeBlock", {
					fg = kanagawa_colors.waveAqua2,
					bg = kanagawa_colors.sumiInk2
				})
				vim.api.nvim_set_hl(0, "MarkviewInlineCode", {
					fg = kanagawa_colors.sakuraPink,
					bg = kanagawa_colors.sumiInk3
				})
				vim.api.nvim_set_hl(0, "MarkviewLink", {
					fg = kanagawa_colors.springBlue,
					underline = true
				})
				vim.api.nvim_set_hl(0, "MarkviewBold", { bold = true })
				vim.api.nvim_set_hl(0, "MarkviewItalic", { italic = true })
				vim.api.nvim_set_hl(0, "MarkviewListMarker", {
					fg = kanagawa_colors.oniViolet
				})
				vim.api.nvim_set_hl(0, "MarkviewCheckboxChecked", {
					fg = kanagawa_colors.springGreen,
					bold = true
				})
				vim.api.nvim_set_hl(0, "MarkviewCheckboxUnchecked", {
					fg = kanagawa_colors.sumiInk4
				})
			end,
		})
	end,
	keys = {
		{ "<leader>mp", "<cmd>Markview toggleAll<cr>", desc = "Toggle Markdown Preview" },
	},
}
