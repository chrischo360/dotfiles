return {
	"stevearc/conform.nvim",
	branch = "nvim-0.9",
	event = { "BufWritePre" },
	cmd = { "ConformInfo" },
	keys = {
		{
			-- Customize or remove this keymap to your liking
			"<leader>f",
			function()
				require("conform").format({ async = true })
			end,
			mode = "",
			desc = "Format buffer",
		},
	},
	-- Change
	-- This will provide type hinting with LuaLS
	---@module "conform"
	---@type conform.setupOpts
	opts = {
		-- Define your formatters
		formatters_by_ft = {
			lua = { "stylua" },
			python = { "isort", "black" },
			javascript = { "prettier" },
			typescript = { "prettier" },
			javascriptreact = { "prettier" },
			typescriptreact = { "prettier" },
			css = { "prettier" },
			scss = { "prettier" },
			html = { "prettier" },
			json = { "prettier" },
			yaml = { "prettier" },
			markdown = { "prettier" },
			graphql = { "prettier" },
			sh = { "shfmt" },
			bash = { "shfmt" },
			go = { "gofmt" },
			rust = { "rustfmt" },
			cpp = { "clang-format" },
			c = { "clang-format" },
		},
		-- Set default options
		default_format_opts = {
			lsp_format = "fallback",
		},
		-- Set up format-on-save
		format_on_save = { timeout_ms = 500 },
		-- Customize formatters
		formatters = {
			prettier = {
				prepend_args = {
					"--tab-width",
					"2",
					"--use-tabs",
					"false",
					"--single-quote",
					"true",
					"--trailing-comma",
					"none",
				},
			},
			stylua = {
				prepend_args = {
					"--indent-width",
					"2",
					"--indent-type",
					"spaces",
				},
			},
			shfmt = {
				prepend_args = { "-i", "2" },
			},
		},
	},
	init = function()
		-- If you want the formatexpr, here is the place to set it
		vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"
	end,
}
