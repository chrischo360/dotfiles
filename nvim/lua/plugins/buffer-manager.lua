return {
  "j-morano/buffer_manager.nvim",
  dependencies = { "nvim-lua/plenary.nvim" },
  keys = {
    { "<leader>b", "<cmd>lua require('buffer_manager.ui').toggle_quick_menu()<cr>", desc = "Buffer Manager" },
    { "<leader>d", "<cmd>lua require('buffer_manager.ui').delete_buffer()<cr>", desc = "Delete Buffer" },
  },
  opts = {
    select_menu_item_commands = {
      v = {
        key = "<C-v>",
        command = "vsplit"
      },
      h = {
        key = "<C-h>",
        command = "split"
      }
    },
    width = 0.8,
    height = 0.8,
  }
}
