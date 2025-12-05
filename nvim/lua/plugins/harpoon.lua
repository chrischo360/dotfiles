-- Plugin: Harpoon
-- Description: Quick navigation between frequently used files (like browser tabs). Mark files and jump between them instantly.
-- Keybindings: <leader>ha (add file), <leader>hh (menu), <M-h/j/k/l> (jump to files 1-4)

return {
  "ThePrimeagen/harpoon",
  branch = "harpoon2",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-telescope/telescope.nvim", -- Optional: for telescope integration
  },
  keys = {
    -- Phase 1: Basic functionality (test these first!)
    {
      "<leader>ha",
      function()
        require("harpoon"):list():add()
      end,
      desc = "Harpoon: Add file",
    },
    {
      "<leader>hh",
      function()
        local harpoon = require("harpoon")
        harpoon.ui:toggle_quick_menu(harpoon:list())
      end,
      desc = "Harpoon: Toggle menu",
    },

    -- Phase 2: Essential navigation keymaps
    -- Jump to specific marks (1-4)
    {
      "<leader>h1",
      function()
        require("harpoon"):list():select(1)
      end,
      desc = "Harpoon: Go to file 1",
    },
    {
      "<leader>h2",
      function()
        require("harpoon"):list():select(2)
      end,
      desc = "Harpoon: Go to file 2",
    },
    {
      "<leader>h3",
      function()
        require("harpoon"):list():select(3)
      end,
      desc = "Harpoon: Go to file 3",
    },
    {
      "<leader>h4",
      function()
        require("harpoon"):list():select(4)
      end,
      desc = "Harpoon: Go to file 4",
    },

    -- Alternative: Ctrl-based navigation (ThePrimeagen style)
    -- These use Alt key to avoid conflicts with your window navigation
    {
      "<M-h>",
      function()
        require("harpoon"):list():select(1)
      end,
      desc = "Harpoon: Go to file 1",
    },
    {
      "<M-j>",
      function()
        require("harpoon"):list():select(2)
      end,
      desc = "Harpoon: Go to file 2",
    },
    {
      "<M-k>",
      function()
        require("harpoon"):list():select(3)
      end,
      desc = "Harpoon: Go to file 3",
    },
    {
      "<M-l>",
      function()
        require("harpoon"):list():select(4)
      end,
      desc = "Harpoon: Go to file 4",
    },

    -- Navigate to next/previous mark
    {
      "<leader>hn",
      function()
        require("harpoon"):list():next()
      end,
      desc = "Harpoon: Next file",
    },
    {
      "<leader>hp",
      function()
        require("harpoon"):list():prev()
      end,
      desc = "Harpoon: Previous file",
    },

    -- Remove current file from list
    {
      "<leader>hd",
      function()
        require("harpoon"):list():remove()
      end,
      desc = "Harpoon: Remove file",
    },
    {
      "<leader>hc",
      function()
        require("harpoon"):list():clear()
      end,
      desc = "Harpoon: Clear all",
    },

    -- Phase 3: Telescope integration
    {
      "<leader>ht",
      function()
        local conf = require("telescope.config").values
        local harpoon_files = require("harpoon"):list()
        local file_paths = {}
        for i, item in ipairs(harpoon_files.items) do
          table.insert(file_paths, item.value)
        end

        require("telescope.pickers")
          .new({}, {
            prompt_title = "Harpoon",
            finder = require("telescope.finders").new_table({
              results = file_paths,
            }),
            previewer = conf.file_previewer({}),
            sorter = conf.generic_sorter({}),
          })
          :find()
      end,
      desc = "Harpoon: Telescope menu",
    },
  },
  config = function()
    local harpoon = require("harpoon")

    -- Phase 1 & 2: Basic setup
    harpoon:setup({
      settings = {
        save_on_toggle = true, -- Save marks when toggling menu
        sync_on_ui_close = true, -- Sync changes when closing UI
        key = function()
          -- Per-project harpoon marks based on git root or cwd
          return vim.loop.cwd()
        end,
      },
    })

    -- Phase 3: UI Customization
    -- Better looking menu with borders
    local harpoon_ui_group = vim.api.nvim_create_augroup("HarpoonUI", { clear = true })
    vim.api.nvim_create_autocmd("FileType", {
      group = harpoon_ui_group,
      pattern = "harpoon",
      callback = function()
        vim.opt_local.cursorline = true
        vim.opt_local.number = false
        vim.opt_local.relativenumber = false
      end,
    })

    -- Optional: Set up telescope extension if available
    local has_telescope, telescope = pcall(require, "telescope")
    if has_telescope then
      -- Note: Harpoon 2 doesn't have official telescope extension yet
      -- We're using the custom picker defined in the keymaps above
    end
  end,
}
