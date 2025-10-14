return {
  "greggh/claude-code.nvim",
  -- plenary.nvim is a required dependency for git operations
  dependencies = {
    "nvim-lua/plenary.nvim",
  },
  config = function()
    -- A minimal configuration for claude-code.nvim
    require("claude-code").setup({
      -- Explicitly tell the plugin how to run the claude command
      -- This ensures that your Zsh environment variables are loaded.
      command = "zsh -c 'source ~/.zshrc && claude'",
      keymaps = {
        toggle = {
          -- Set your desired keymap for normal mode
          normal = "<leader>cc",

          -- Disable the default keymap (<C-,>) to avoid conflicts
          terminal = false,
        },
        -- We'll let the plugin use its sensible defaults for other features
        -- like window navigation and scrolling.
      },
    })
  end
}
