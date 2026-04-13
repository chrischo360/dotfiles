return {
  "stevearc/conform.nvim",
  -- branch = "nvim-0.9", -- Removed: main branch supports nvim 0.12
  event = { "BufWritePre" },
  cmd = { "ConformInfo" },
  keys = {
    {
      -- Customize or remove this keymap to your liking
      "<leader>F",
      function()
        local conform = require("conform")
        local bufnr = vim.api.nvim_get_current_buf()
        local filepath = vim.api.nvim_buf_get_name(bufnr)
        local filename = vim.fn.fnamemodify(filepath, ":t")

        -- Get formatters for current buffer (only available ones)
        local formatters = conform.list_formatters(bufnr)
        local available_formatters = {}
        for _, f in ipairs(formatters) do
          if f.available then
            table.insert(available_formatters, f.name)
          end
        end

        local success = conform.format({ async = false, timeout_ms = 60000 })

        if success then
          if #available_formatters > 0 then
            print("✓ Formatted " .. filename .. " with: " .. table.concat(available_formatters, ", "))
          else
            print("✓ Formatted " .. filename)
          end
        else
          print("✗ Formatting failed for " .. filename)
        end
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
      javascript = { "biome", "prettier", stop_after_first = true },
      typescript = { "biome", "prettier", stop_after_first = true },
      javascriptreact = { "biome", "prettier", stop_after_first = true },
      typescriptreact = { "biome", "prettier", stop_after_first = true },
      json = { "biome", "prettier", stop_after_first = true },
      jsonc = { "biome", "prettier", stop_after_first = true },
      css = { "biome", "prettier", stop_after_first = true },
      -- Fallback to prettier for formats biome doesn't support yet
      scss = { "prettier" },
      html = { "prettier" },
      yaml = { "prettier" },
      -- markdown = { "prettier" }, -- DISABLED: No auto-formatting for markdown
      graphql = { "prettier" },
      graphqls = { "prettier" },
      svelte = { "prettier" },
      sh = { "shfmt" },
      bash = { "shfmt" },
      go = { "gofmt" },
      rust = { "rustfmt" },
      cpp = { "clang-format" },
      c = { "clang-format" },
      swift = { "swift_format" },
      scala = { "scalafmt" },
      php = { "company_php_fixer" }, -- DISABLED
    },
    -- Set default options
    default_format_opts = {
      lsp_format = "fallback",
    },
    -- Set up format-on-save
    format_on_save = function(bufnr)
      -- DISABLED: Format on save disabled globally
      -- Use <leader>F to format manually
      return false
    end,
    -- Customize formatters
    formatters = {
      biome = {
        -- Biome uses biome.json for configuration, but you can pass args here
        -- By default it will look for biome.json in your project root
        prepend_args = {},
        -- Only run if biome.json or biome.jsonc exists in project
        condition = function(self, ctx)
          return vim.fn.findfile("biome.json", ".;") ~= "" or vim.fn.findfile("biome.jsonc", ".;") ~= ""
        end,
      },
      prettier = {
        -- Respect project's prettier config (prettier.config.js, .prettierrc, etc.)
        prepend_args = {},
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
      rustfmt = {
        -- Let rustfmt infer edition from Cargo.toml or use default
        prepend_args = {},
      },
      swift_format = {
        command = "swift-format",
        args = { "$FILENAME" },
        stdin = false,
      },
      company_php_fixer = {
        command = function()
          local ok, result = pcall(function()
            -- Prioritize the comprehensive fix.php script
            local fix_script = vim.fn.findfile("vendor-bin/cs/fix.php", ".;")
            if fix_script ~= "" then
              return "/opt/homebrew/opt/php@8.1/bin/php"
            end
            -- Fallback to project phpcbf
            local project_phpcbf = vim.fn.findfile("includes/sdk/composer-packages/bin/phpcbf", ".;")
            if project_phpcbf ~= "" then
              return "/opt/homebrew/opt/php@8.1/bin/php"
            end
            -- Global fallback
            return "phpcbf"
          end)
          return ok and result or "phpcbf"
        end,
        args = function(self, ctx)
          local ok, result = pcall(function()
            -- DISABLED: Skip the comprehensive fix.php script (too slow)
            -- local fix_script = vim.fn.findfile("vendor-bin/cs/fix.php", ".;")
            -- if fix_script ~= "" then
            --   return { fix_script, "$FILENAME" }
            -- end
            -- Use project phpcbf instead
            local project_phpcbf = vim.fn.findfile("includes/sdk/composer-packages/bin/phpcbf", ".;")
            if project_phpcbf ~= "" then
              return { project_phpcbf, "--standard=CSNStores", "$FILENAME" }
            end
            -- Global fallback
            return { "--standard=PSR12", "$FILENAME" }
          end)
          return ok and result or { "--standard=PSR12", "$FILENAME" }
        end,
        stdin = false,
        timeout_ms = 60000, -- Extra timeout for comprehensive formatting (60 seconds)
      },
      phpcbf = {
        command = function()
          -- Try to find the company's comprehensive fix.php script first
          local fix_script = vim.fn.findfile("vendor-bin/cs/fix.php", ".;")
          if fix_script ~= "" then
            return "/opt/homebrew/opt/php@8.1/bin/php"
          end
          -- Try to find the project-specific phpcbf second
          local project_phpcbf = vim.fn.findfile("includes/sdk/composer-packages/bin/phpcbf", ".;")
          if project_phpcbf ~= "" then
            return "/opt/homebrew/opt/php@8.1/bin/php"
          end
          -- Fall back to global phpcbf
          return "phpcbf"
        end,
        args = function(self, ctx)
          -- Try to find the company's comprehensive fix.php script first
          local fix_script = vim.fn.findfile("vendor-bin/cs/fix.php", ".;")
          if fix_script ~= "" then
            return { fix_script, "$FILENAME" }
          end
          -- Try to find the project-specific phpcbf second
          local project_phpcbf = vim.fn.findfile("includes/sdk/composer-packages/bin/phpcbf", ".;")
          if project_phpcbf ~= "" then
            return { project_phpcbf, "--standard=CSNStores", "$FILENAME" }
          end
          -- Fall back to global phpcbf with PSR12
          return { "--standard=PSR12", "$FILENAME" }
        end,
        stdin = false,
      },
    },
  },
  init = function()
    -- If you want the formatexpr, here is the place to set it
    vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"

    -- Debug function to check which PHP formatter will be used
    vim.api.nvim_create_user_command("DebugPHPFormatter", function()
      local fix_script = vim.fn.findfile("vendor-bin/cs/fix.php", ".;")
      local project_phpcbf = vim.fn.findfile("includes/sdk/composer-packages/bin/phpcbf", ".;")

      print("=== PHP Formatter Detection ===")
      print("Working directory: " .. vim.fn.getcwd())
      print("PHP Version: 8.1 (/opt/homebrew/opt/php@8.1/bin/php)")
      print("fix.php found: " .. (fix_script ~= "" and fix_script or "NOT FOUND"))
      print("phpcbf found: " .. (project_phpcbf ~= "" and project_phpcbf or "NOT FOUND"))
      print("")

      if fix_script ~= "" then
        print("✅ WILL USE: /opt/homebrew/opt/php@8.1/bin/php " .. fix_script .. " filename.php")
        print("🚀 COMPREHENSIVE FORMATTING (PHP-CS-Fixer + PHPCBF + Rector)")
      elseif project_phpcbf ~= "" then
        print(
          "✅ WILL USE: /opt/homebrew/opt/php@8.1/bin/php " .. project_phpcbf .. " --standard=CSNStores filename.php"
        )
        print("🔧 BASIC PHPCBF with CSNStores")
      else
        print("✅ WILL USE: phpcbf --standard=PSR12 filename.php")
        print("📋 GLOBAL PHPCBF with PSR12")
      end
    end, {})

    -- Test PHP formatter manually (doesn't require saving)
    vim.api.nvim_create_user_command("TestPHPFormatter", function()
      local bufnr = vim.api.nvim_get_current_buf()
      print("Testing PHP formatter on current buffer...")
      require("conform").format({
        bufnr = bufnr,
        timeout_ms = 20000,
        quiet = false,
      })
    end, {})

    -- Company-specific PHP commands for manual checking and fixing:
    --
    -- COMPREHENSIVE FORMATTER (PHP-CS-Fixer + PHPCBF + Rector):
    -- :!php vendor-bin/cs/fix.php %
    --
    -- To check for sniff issues (PHPCS):
    -- :!php includes/sdk/composer-packages/bin/phpcs -p --colors --report=full --standard=CSNStores --warning-severity=0 %
    --
    -- To fix issues with PHPCBF only:
    -- :!php includes/sdk/composer-packages/bin/phpcbf --standard=CSNStores %
    --
    -- DEBUG: Check which formatter will be used:
    -- :DebugPHPFormatter
  end,
}
