-- Plugin: Neo-tree
-- Description: File explorer sidebar with tree view. Shows hidden files by default and follows current file.
-- Commands: :NT (toggle explorer)

return {
  "nvim-neo-tree/neo-tree.nvim",
  branch = "v3.x",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-tree/nvim-web-devicons", -- not strictly required, but recommended
    "MunifTanjim/nui.nvim",
    "3rd/image.nvim", -- Optional image support in preview window: See `# Preview Mode` for more information
  },
  keys = {
    {
      "<leader>e",
      function()
        require("neo-tree.command").execute({ toggle = true })
      end,
      desc = "Toggle NeoTree",
    },
  },
  config = function()
    require("neo-tree").setup({
      -- Auto-reveal configuration
      filesystem = {
        filtered_items = {
          visible = true, -- Show hidden files by default
          hide_dotfiles = false,
          hide_gitignored = true,
          hide_hidden = false, -- Windows hidden attribute
        },
        follow_current_file = {
          enabled = true, -- This will find and focus the file in the tree
          leave_dirs_open = true, -- Keep directories open when navigating
        },
        hijack_netrw_behavior = "open_current", -- Open neo-tree when opening a directory
      },

      window = {
        mappings = {
          ["<C-h>"] = function()
            vim.cmd("wincmd h")
          end,
          ["<C-j>"] = function()
            vim.cmd("wincmd j")
          end,
          ["<C-k>"] = function()
            vim.cmd("wincmd k")
          end,
          ["<C-l>"] = function()
            vim.cmd("wincmd l")
          end,
        },
      },
    })

    -- Keep these window movement keymaps
    vim.keymap.set("n", "<C-h>", "<C-w>h", { noremap = true, silent = true })
    vim.keymap.set("n", "<C-j>", "<C-w>j", { noremap = true, silent = true })
    vim.keymap.set("n", "<C-k>", "<C-w>k", { noremap = true, silent = true })
    vim.keymap.set("n", "<C-l>", "<C-w>l", { noremap = true, silent = true })

    -- Create :NT command to toggle NeoTree
    vim.api.nvim_create_user_command("NT", function()
      require("neo-tree.command").execute({ toggle = true })
    end, { desc = "Toggle NeoTree" })
  end,
}
