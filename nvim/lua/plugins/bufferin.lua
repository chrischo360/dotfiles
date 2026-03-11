-- Plugin: Bufferin
-- Description: Buffer management interface for viewing and switching between open files/buffers.
-- Keybindings: <leader>b (toggle buffer list)

return {
  "wasabeef/bufferin.nvim",
  keys = {
    { "<leader>b", "<cmd>Bufferin<cr>", desc = "Toggle Bufferin" },
  },
  config = function()
    require("bufferin").setup({
      display = {
        show_numbers = false,
        show_path = false,
        show_icons = true,
        show_modified = true,
      }
    })
  end,
  dependencies = {
    "nvim-tree/nvim-web-devicons",
  },
}
