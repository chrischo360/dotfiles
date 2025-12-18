return {
  dir = vim.fn.stdpath("config") .. "/lua/claude",
  name = "claude-nvim",
  config = function()
    require("claude").setup()
  end,
  keys = {
    {
      "<leader>c",
      ":Claude<CR>",
      mode = "v",
      desc = "Send to Claude Code",
    },
  },
}
