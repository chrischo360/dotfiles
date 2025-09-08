return {
	{
		"neovim/nvim-lspconfig",
		event = { "BufReadPre", "BufNewFile" },
		dependencies = {
			"williamboman/mason.nvim",
			"williamboman/mason-lspconfig.nvim",
			"hrsh7th/nvim-cmp",
			"hrsh7th/cmp-nvim-lsp",
			"rafamadriz/friendly-snippets", -- Faster snippet engine
			"L3MON4D3/LuaSnip",
			"saadparwaiz1/cmp_luasnip",
			"hrsh7th/cmp-buffer",
			"hrsh7th/cmp-path",
		},
		config = function()
			local capabilities = require("cmp_nvim_lsp").default_capabilities()
			-- Diagnostic configuration for performance
			vim.diagnostic.config({
				virtual_text = false, -- Disable inline diagnostics
				update_in_insert = false,
				severity_sort = true,
				float = {
					border = "rounded",
					source = "always",
					header = "",
					prefix = "",
				},
			})

			-- Mason Setup
			require("mason").setup({
				ui = {
					icons = {
						package_installed = "✓",
						package_pending = "➜",
						package_uninstalled = "✗",
					},
				},
			})
			require("mason-lspconfig").setup({
				ensure_installed = { "pyright", "lua_ls", "ts_ls", "jdtls", "intelephense", "rust_analyzer" },
				automatic_installation = true,
			})

			-- LSP Keybindings
			vim.api.nvim_create_autocmd("LspAttach", {
				desc = "LSP actions",
				callback = function(event)
					local opts = { buffer = event.buf }
					vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
					vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
					vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts)
					vim.keymap.set("n", "gi", vim.lsp.buf.implementation, opts)
					vim.keymap.set("n", "go", vim.lsp.buf.type_definition, opts)
					vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
					vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
					vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts)
					vim.keymap.set("n", "<leader>f", vim.lsp.buf.format, opts)
				end,
			})

			-- LSP Server Configurations
			local lspconfig = require("lspconfig")

			-- Lua
			lspconfig.lua_ls.setup({
				capabilities = capabilities,
				settings = {
					Lua = {
						diagnostics = {
							globals = { "vim" },
						},
						workspace = {
							checkThirdParty = false, -- Improve startup time
							library = {
								vim.env.VIMRUNTIME,
							},
						},
					},
				},
			})

			-- Python
			lspconfig.pyright.setup({
				capabilities = capabilities,
				settings = {
					python = {
						analysis = {
							typeCheckingMode = "basic", -- Less aggressive type checking
						},
					},
				},
			})

			-- TypeScript
			lspconfig.ts_ls.setup({
				capabilities = capabilities,
			})

			-- Java
			lspconfig.jdtls.setup({
				capabilities = capabilities,
				settings = {
					java = {
						signatureHelp = { enabled = true },
						contentProvider = { preferred = "fernflower" },
						completion = {
							favoriteStaticMembers = {
								"org.hamcrest.MatcherAssert.assertThat",
								"org.hamcrest.Matchers.*",
								"org.junit.Assert.*",
								"org.junit.Assume.*",
								"org.junit.jupiter.api.Assertions.*",
								"org.junit.jupiter.api.Assumptions.*",
								"org.junit.jupiter.api.DynamicContainer.*",
								"org.junit.jupiter.api.DynamicTest.*",
								"java.util.Objects.requireNonNull",
								"java.util.Objects.requireNonNullElse",
							},
						},
						sources = {
							organizeImports = {
								starThreshold = 9999,
								staticStarThreshold = 9999,
							},
						},
						codeGeneration = {
							toString = {
								template =
								"${object.className}{${member.name()}=${member.value}, ${otherMembers}}",
							},
							useBlocks = true,
						},
						configuration = {
							runtimes = {
								{
									name = "JavaSE-11",
									path = "~/.sdkman/candidates/java/11.0.12-open",
								},
								{
									name = "JavaSE-17",
									path = "~/.sdkman/candidates/java/17.0.5-tem",
								},
							},
						},
					},
				},
			})

			-- PHP
			lspconfig.intelephense.setup({
				capabilities = capabilities,
				settings = {
					intelephense = {
						files = {
							maxSize = 1000000,
						},
						environment = {
							phpVersion = "8.2", -- Set your PHP version
						},
						stubs = {
							"apache", "bcmath", "bz2", "calendar", "com_dotnet", "Core",
							"ctype", "curl", "date", "dba", "dom", "enchant", "exif",
							"FFI", "fileinfo", "filter", "fpm", "ftp", "gd", "gettext",
							"gmp", "hash", "iconv", "imap", "intl", "json", "ldap",
							"libxml", "mbstring", "meta", "mysqli", "oci8", "odbc",
							"openssl", "pcntl", "pcre", "PDO", "pdo_ibm", "pdo_mysql",
							"pdo_pgsql", "pdo_sqlite", "pgsql", "Phar", "posix",
							"pspell", "readline", "Reflection", "session", "shmop",
							"SimpleXML", "snmp", "soap", "sockets", "sodium", "SPL",
							"sqlite3", "standard", "superglobals", "sysvmsg", "sysvsem",
							"sysvshm", "tidy", "tokenizer", "xml", "xmlreader",
							"xmlrpc", "xmlwriter", "xsl", "Zend OPcache", "zip", "zlib",
							"wordpress", "phpunit", "laravel", "symfony"
						},
						diagnostics = {
							enable = true,
						},
						format = {
							enable = true,
						},
					},
				},
			})

			-- Rust
			lspconfig.rust_analyzer.setup({
				capabilities = capabilities,
				settings = {
					["rust-analyzer"] = {
						cargo = {
							allFeatures = true,
							loadOutDirsFromCheck = true,
							runBuildScripts = true,
						},
						-- Add clippy lints for Rust.
						checkOnSave = {
							allFeatures = true,
							command = "clippy",
							extraArgs = { "--no-deps" },
						},
						procMacro = {
							enable = true,
							ignored = {
								["async-trait"] = { "async_trait" },
								["napi-derive"] = { "napi" },
								["async-recursion"] = { "async_recursion" },
							},
						},
					},
				},
			})
			-- Completion Setup
			local cmp = require("cmp")
			local luasnip = require("luasnip")
			require("luasnip.loaders.from_vscode").lazy_load()

			cmp.setup({
				snippet = {
					expand = function(args)
						luasnip.lsp_expand(args.body)
					end,
				},
				performance = {
					debounce = 150, -- Debounce completion
					throttle = 75, -- Throttle completion
					fetching_timeout = 200,
				},
				mapping = cmp.mapping.preset.insert({
					["<C-d>"] = cmp.mapping.scroll_docs(-4),
					["<C-f>"] = cmp.mapping.scroll_docs(4),
					["<C-Space>"] = cmp.mapping.complete(),
					["<CR>"] = cmp.mapping.confirm({
						behavior = cmp.ConfirmBehavior.Replace,
						select = true,
					}),
					["<Tab>"] = cmp.mapping(function(fallback)
						if cmp.visible() then
							cmp.select_next_item()
						elseif luasnip.expand_or_jumpable() then
							luasnip.expand_or_jump()
						else
							fallback()
						end
					end, { "i", "s" }),
					["<S-Tab>"] = cmp.mapping(function(fallback)
						if cmp.visible() then
							cmp.select_prev_item()
						elseif luasnip.jumpable(-1) then
							luasnip.jump(-1)
						else
							fallback()
						end
					end, { "i", "s" }),
				}),
				sources = cmp.config.sources({
					{ name = "nvim_lsp", max_item_count = 10 },
					{ name = "luasnip",  max_item_count = 5 },
				}, {
					{ name = "buffer", max_item_count = 5 },
					{ name = "path",   max_item_count = 3 },
				}),
				sorting = {
					comparators = {
						cmp.config.compare.offset,
						cmp.config.compare.exact,
						cmp.config.compare.score,
					},
				},
			})
		end,
	},
}
