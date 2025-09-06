return {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons", -- not strictly required, but recommended
      "MunifTanjim/nui.nvim",
      -- "3rd/image.nvim", -- Optional image support in preview window: See `# Preview Mode` for more information
    },
    keys = {
    {
      "<leader>e",
      function()
        require("neo-tree.command").execute({ toggle = true })
      end,
      desc = "Toggle Explorer",
    },
  },
  config = function()
    require("neo-tree").setup({
      window = {
        mappings = {
          ["<C-h>"] = function() vim.cmd("wincmd h") end,
          ["<C-l>"] = function() vim.cmd("wincmd l") end,
        }
      }
    })

    -- Keep these window movement keymaps
    vim.keymap.set('n', '<C-h>', '<C-w>h', { noremap = true, silent = true })
    vim.keymap.set('n', '<C-l>', '<C-w>l', { noremap = true, silent = true })
  end
}
