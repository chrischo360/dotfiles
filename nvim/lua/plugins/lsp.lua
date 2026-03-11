-- Plugin: LSP Configuration (nvim-lspconfig + Mason)
-- Description: Language Server Protocol integration with auto-completion, diagnostics, and code navigation.
--              Includes Mason for managing LSP servers (Lua, Python, TypeScript, Java, PHP, Rust, Swift).
-- Keybindings: gd (definition), gr (references), K (hover), <leader>rn (rename), <leader>ca (code action)

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
        virtual_text = {
          severity = { min = vim.diagnostic.severity.WARN }, -- Only warnings and errors
          prefix = "●",
          source = "if_many",
        },
        update_in_insert = false,
        severity_sort = true,
        float = {
          border = "rounded",
          source = "always",
          header = "",
          prefix = "",
        },
      })

      -- Override default floating window border for LSP
      local orig_util_open_floating_preview = vim.lsp.util.open_floating_preview
      function vim.lsp.util.open_floating_preview(contents, syntax, opts, ...)
        opts = opts or {}
        opts.border = opts.border or "rounded"
        opts.max_width = opts.max_width or 80
        opts.max_height = opts.max_height or 20
        return orig_util_open_floating_preview(contents, syntax, opts, ...)
      end

      -- Enable inlay hints for all LSP servers that support it
      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("LspInlayHints", { clear = true }),
        callback = function(args)
          local client = vim.lsp.get_client_by_id(args.data.client_id)
          if client and client.server_capabilities.inlayHintProvider then
            vim.lsp.inlay_hint.enable(true, { bufnr = args.buf })
          end
        end,
      })

      -- Hide inlay hints on the current line and in insert/visual mode
      -- local inlay_hint_group = vim.api.nvim_create_augroup("InlayHintsCursorLine", { clear = true })
      --
      -- local function update_inlay_hints()
      --   local bufnr = vim.api.nvim_get_current_buf()
      --   local mode = vim.api.nvim_get_mode().mode
      --
      --   -- Disable in insert or visual mode, or when on the current line
      --   if mode == 'i' or mode == 'v' or mode == 'V' or mode == '\22' then -- \22 is visual block mode
      --     vim.lsp.inlay_hint.enable(false, { bufnr = bufnr })
      --   else
      --     vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
      --   end
      -- end
      --
      -- -- Update on mode change
      -- vim.api.nvim_create_autocmd({ "ModeChanged", "CursorMoved", "CursorMovedI" }, {
      --   group = inlay_hint_group,
      --   callback = update_inlay_hints,
      -- })

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
        ensure_installed = { "pyright", "lua_ls", "ts_ls", "jdtls", "intelephense", "rust_analyzer", "svelte", "graphql" },
        automatic_installation = true,
      })

      -- LSP Keybindings
      vim.api.nvim_create_autocmd("LspAttach", {
        desc = "LSP actions",
        callback = function(event)
          local opts = { buffer = event.buf }
          vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
          vim.keymap.set("i", "<C-k>", vim.lsp.buf.signature_help, opts)
          vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
          vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts)
          vim.keymap.set("n", "gi", vim.lsp.buf.implementation, opts)
          vim.keymap.set("n", "go", vim.lsp.buf.type_definition, opts)
          vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
          vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
          vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts)
          -- vim.keymap.set("n", "<leader>f", vim.lsp.buf.format, opts) -- Disabled: conflicts with conform.nvim
          vim.keymap.set("n", "<leader>ds", function()
            require("telescope.builtin").lsp_document_symbols({
              bufnr = event.buf,
              default_text = "",
            })
          end, vim.tbl_extend("force", opts, { desc = "Document symbols" }))

          -- Diagnostic keymaps
          vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, opts)
          vim.keymap.set("n", "]d", vim.diagnostic.goto_next, opts)
          vim.keymap.set("n", "gl", vim.diagnostic.open_float, opts)
          vim.keymap.set("n", "<leader>xl", vim.diagnostic.setloclist, opts)
          vim.keymap.set("n", "<leader>xq", vim.diagnostic.setqflist, opts)

          -- Toggle inlay hints
          vim.keymap.set("n", "<leader>th", function()
            vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
          end, vim.tbl_extend("force", opts, { desc = "Toggle inlay hints" }))
        end,
      })

      -- LSP Server Configurations
      -- Lua
      vim.lsp.config('lua_ls', {
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
      vim.lsp.config('pyright', {
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
      vim.lsp.config('ts_ls', {
        capabilities = capabilities,
        settings = {
          typescript = {
            inlayHints = {
              includeInlayParameterNameHints = "literals", -- Only show on literal values, not variables
              includeInlayFunctionParameterTypeHints = true,
              includeInlayVariableTypeHints = false, -- Disabled: too verbose, shows huge types
              includeInlayFunctionLikeReturnTypeHints = true,
            },
          },
          javascript = {
            inlayHints = {
              includeInlayParameterNameHints = "literals", -- Only show on literal values, not variables
              includeInlayFunctionParameterTypeHints = true,
              includeInlayVariableTypeHints = false, -- Disabled: too verbose, shows huge types
              includeInlayFunctionLikeReturnTypeHints = true,
            },
          },
        },
      })

      -- Java
      vim.lsp.config('jdtls', {
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
                template = "${object.className}{${member.name()}=${member.value}, ${otherMembers}}",
              },
              useBlocks = true,
            },
            configuration = {
              runtimes = {
                {
                  name = "JavaSE-11",
                  path = vim.fn.expand("~/.sdkman/candidates/java/11.0.12-open"),
                },
                {
                  name = "JavaSE-17",
                  path = vim.fn.expand("~/.sdkman/candidates/java/17.0.5-tem"),
                },
              },
            },
          },
        },
      })

      -- PHP
      vim.lsp.config('intelephense', {
        capabilities = capabilities,
        settings = {
          intelephense = {
            files = {
              maxSize = 1000000,
              exclude = {
                "**/.git/**",
                "**/.svn/**",
                "**/.hg/**",
                "**/CVS/**",
                "**/.DS_Store/**",
                "**/node_modules/**",
                "**/bower_components/**",
                "**/vendor/**/Tests/**",
                "**/vendor/**/tests/**",
                "**/vendor/**/.git/**",
                "**/vendor-bin/**",
                "**/cache/**",
                "**/tmp/**",
                "**/temp/**",
                "**/storage/framework/**",
                "**/storage/logs/**",
                "**/bootstrap/cache/**",
                "**/tests/**", -- Exclude test directories for performance
                "**/.buildkite/**",
                "**/.github/**",
                "**/bundler/**",
                "**/*.min.js",
                "**/*.min.css",
              },
            },
            environment = {
              phpVersion = "8.1", -- Updated to PHP 8.1
              includePaths = {}, -- Clear default include paths to reduce indexing
            },
            stubs = {
              "apache",
              "bcmath",
              "bz2",
              "calendar",
              "com_dotnet",
              "Core",
              "ctype",
              "curl",
              "date",
              "dba",
              "dom",
              "enchant",
              "exif",
              "FFI",
              "fileinfo",
              "filter",
              "fpm",
              "ftp",
              "gd",
              "gettext",
              "gmp",
              "hash",
              "iconv",
              "imap",
              "intl",
              "json",
              "ldap",
              "libxml",
              "mbstring",
              "meta",
              "mysqli",
              "oci8",
              "odbc",
              "openssl",
              "pcntl",
              "pcre",
              "PDO",
              "pdo_ibm",
              "pdo_mysql",
              "pdo_pgsql",
              "pdo_sqlite",
              "pgsql",
              "Phar",
              "posix",
              "pspell",
              "readline",
              "Reflection",
              "session",
              "shmop",
              "SimpleXML",
              "snmp",
              "soap",
              "sockets",
              "sodium",
              "SPL",
              "sqlite3",
              "standard",
              "superglobals",
              "sysvmsg",
              "sysvsem",
              "sysvshm",
              "tidy",
              "tokenizer",
              "xml",
              "xmlreader",
              "xmlrpc",
              "xmlwriter",
              "xsl",
              "Zend OPcache",
              "zip",
              "zlib",
              "wordpress",
              "phpunit",
              "laravel",
              "symfony",
            },
            diagnostics = {
              enable = true,
            },
            format = {
              enable = true,
            },
            -- Performance optimizations
            completion = {
              insertUseDeclaration = true,
              fullyQualifyGlobalConstantsAndFunctions = false,
              maxItems = 100, -- Limit completion items
            },
            indexing = {
              maxFileSize = 1000000, -- 1MB max file size for indexing
            },
          },
        },
      })

      -- Rust
      vim.lsp.config('rust_analyzer', {
        capabilities = capabilities,
        settings = {
          ["rust-analyzer"] = {
            checkOnSave = true, -- FIXED: boolean instead of map
            cargo = {
              allFeatures = true,
              loadOutDirsFromCheck = true,
              runBuildScripts = true,
            },
            procMacro = {
              enable = true,
              ignored = {
                ["async-recursion"] = { "async_recursion" },
                ["async-trait"] = { "async_trait" },
                ["napi-derive"] = { "napi" },
              },
            },
          },
        },
      })

      -- Swift
      vim.lsp.config('sourcekit', {
        capabilities = capabilities,
        cmd = { "sourcekit-lsp" },
        filetypes = { "swift", "objective-c", "objective-cpp" },
        root_dir = function(fname)
          return vim.fs.root(fname, { "Package.swift", ".git" })
        end,
      })

      -- Scala
      vim.lsp.config('metals', {
        cmd = { "/Users/cc446g/.local/bin/metals" },
        capabilities = vim.tbl_deep_extend('force', capabilities, {
          workspace = {
            semanticTokens = {
              refreshSupport = false -- Disable refresh (not supported by Neovim)
            }
          }
        }),
        filetypes = { "scala", "sbt" },
        root_dir = function(fname)
          return vim.fs.root(fname, { "build.sbt", "build.sc", "build.gradle", "pom.xml", ".git" })
        end,
        settings = {
          metals = {
            showImplicitArguments = true,
            showImplicitConversions = true,
            showInferredType = true,
            superMethodLensesEnabled = true,
            enableSemanticHighlighting = false,
          },
        },
      })

      -- Svelte
      vim.lsp.config('svelte', {
        capabilities = capabilities,
        filetypes = { "svelte" },
        settings = {
          svelte = {
            plugin = {
              svelte = {
                compilerWarnings = {
                  ["a11y-missing-attribute"] = "ignore",
                },
              },
            },
          },
        },
      })

      -- GraphQL
      vim.lsp.config('graphql', {
        capabilities = capabilities,
        filetypes = { "graphql", "graphqls", "typescriptreact", "javascriptreact", "typescript", "javascript" },
        root_dir = function(fname)
          return vim.fs.root(fname, { "graphql.config.js", "graphql.config.ts", ".graphqlrc", ".graphqlrc.js", ".graphqlrc.json", ".graphqlrc.yml", ".git" })
        end,
      })

      -- Completion Setup
      local cmp = require("cmp")
      local luasnip = require("luasnip")
      require("luasnip.loaders.from_vscode").lazy_load({
        exclude = { "markdown" },
      })
      require("luasnip.loaders.from_lua").load({
        paths = { vim.fn.stdpath("config") .. "/lua/snippets" },
      })

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
            select = false,
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
          { name = "luasnip", max_item_count = 5 },
        }, {
          { name = "buffer", max_item_count = 5 },
          { name = "path", max_item_count = 3 },
        }),
        sorting = {
          comparators = {
            cmp.config.compare.offset,
            cmp.config.compare.exact,
            cmp.config.compare.score,
          },
        },
      })

      -- Mason-managed servers are auto-started by mason-lspconfig's default handler
      -- But servers with custom root_dir functions or manually-installed ones need explicit enable
      vim.lsp.enable({ 'sourcekit', 'metals', 'graphql' })
    end,
  },
}
