return {
  "greggh/claude-code.nvim",
  dependencies = { "nvim-lua/plenary.nvim" },
  config = function()
    require("claude-code").setup({
      -- Use a login shell to ensure environment variables are loaded correctly and efficiently.
      command = "zsh -l -c 'claude'",

      keymaps = {
        toggle = {
          normal = "<leader>cc",
          terminal = false,
        },
      },
    })
  end
}
