-- Plugin: Bufferin
-- Description: Buffer management interface for viewing and switching between open files/buffers.
-- Keybindings: <leader>b (toggle buffer list)

return {
  "wasabeef/bufferin.nvim",
  keys = {
    { "<leader>b", "<cmd>Bufferin<cr>", desc = "Toggle Bufferin" },
  },
  config = function()
    require("bufferin").setup()
  end,
  -- Optional dependencies for enhanced experience
  dependencies = {
    "nvim-tree/nvim-web-devicons", -- For file icons
    "willothy/nvim-cokeline", -- For buffer line integration
  },
}
