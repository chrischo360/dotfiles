-- File: lua/plugins/claude.lua
-- Claude Code AI Assistant Configuration

return {
  "greggh/claude-code.nvim",
  lazy = false, -- Load immediately for global keymaps
  dependencies = {
    "nvim-telescope/telescope.nvim",
  },
  keys = {
    -- Core functionality
    { "<leader>cc", "<cmd>ClaudeChat<cr>", desc = "Claude Chat" },
    { "<leader>cI", "<cmd>ClaudeChat<cr>", desc = "Claude New Chat" }, -- Simplified: opens the chat view

    -- Code actions
    { "<leader>cg", "<cmd>ClaudeGenerate<cr>", desc = "Generate Code", mode = { "n", "v" } },
    { "<leader>ce", "<cmd>ClaudeExplain<cr>", desc = "Explain Code", mode = "v" },
    { "<leader>cf", "<cmd>ClaudeFix<cr>", desc = "Fix Code", mode = "v" },

    -- Refactoring submenu
    { "<leader>cr", group = "Refactor" },
    { "<leader>crr", "<cmd>ClaudeRefactor<cr>", desc = "Refactor Selection", mode = "v" },
    { "<leader>cri", "<cmd>ClaudeImprove<cr>", desc = "Improve Code", mode = "v" },
    { "<leader>crd", "<cmd>ClaudeAddDocstring<cr>", desc = "Add Docstring", mode = "v" },
    { "<leader>crt", "<cmd>ClaudeAddTests<cr>", desc = "Add Tests", mode = "v" },

    -- Model management submenu
    { "<leader>cm", group = "Model" },
    { "<leader>cmo", "<cmd>ClaudeUseOpus<cr>", desc = "Use Opus (Powerful)" },
    { "<leader>cms", "<cmd>ClaudeUseSonnet<cr>", desc = "Use Sonnet (Balanced)" },
    { "<leader>cmh", "<cmd>ClaudeUseHaiku<cr>", desc = "Use Haiku (Fast)" },
    { "<leader>cmt", "<cmd>Telescope claude_code model<cr>", desc = "Select Model (Telescope)" },

    -- Telescope integration
    { "<leader>ca", "<cmd>Telescope claude_code actions<cr>", desc = "All Actions (Telescope)" },
  },
  config = function()
    -- Define the models you want to use with friendly names
    local models = {
      opus = "claude-opus-4-1@20250805",
      sonnet = "claude-sonnet-4-5@20250929",
      haiku = "claude-3-5-haiku@20241022",
    }

    require("claude_code").setup({
      model = models.opus, -- Default to Opus
      replace_strategy = "visual", -- Show response in a floating window
      http_options = {
        vertex_project = "wf-gcp-us-sf-genai-pilot-sbx",
        vertex_region = "us-east5",
        model_map = {
          Opus = models.opus,
          Sonnet = models.sonnet,
          Haiku = models.haiku,
        },
        temperature = 0.2, -- Optimized for accurate code generation
      },
    })

    -- Load the Telescope extension
    pcall(require("telescope").load_extension, "claude_code")

    -- === Custom Commands for Model Switching ===
    vim.api.nvim_create_user_command("ClaudeUseOpus", function()
      require("claude_code").set_model(models.opus)
      vim.notify("🤖 Claude: Using Opus (Most Powerful)", vim.log.levels.INFO)
    end, { desc = "Switch to Claude Opus model" })

    vim.api.nvim_create_user_command("ClaudeUseSonnet", function()
      require("claude_code").set_model(models.sonnet)
      vim.notify("🤖 Claude: Using Sonnet (Balanced)", vim.log.levels.INFO)
    end, { desc = "Switch to Claude Sonnet model" })

    vim.api.nvim_create_user_command("ClaudeUseHaiku", function()
      require("claude_code").set_model(models.haiku)
      vim.notify("🤖 Claude: Using Haiku (Fastest)", vim.log.levels.INFO)
    end, { desc = "Switch to Claude Haiku model" })
  end,
}
