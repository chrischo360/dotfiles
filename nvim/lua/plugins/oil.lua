-- Plugin: Oil.nvim
-- Description: File explorer that lets you edit your filesystem like a normal Neovim buffer. Works alongside neo-tree for buffer-style file management.
-- Keybindings: <leader>- (toggle oil)

return {
  "stevearc/oil.nvim",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  keys = {
    {
      "<leader>-",
      function()
        local oil = require("oil")
        -- Check if current buffer is an oil buffer
        if vim.bo.filetype == "oil" then
          -- Close the oil buffer
          vim.cmd("bd")
        else
          oil.open()
        end
      end,
      desc = "Toggle Oil (file explorer)",
    },
  },
  config = function()
    -- Declare a global function to retrieve the current directory
    function _G.get_oil_winbar()
      local bufnr = vim.api.nvim_win_get_buf(vim.g.statusline_winid)
      local dir = require("oil").get_current_dir(bufnr)
      if dir then
        return vim.fn.fnamemodify(dir, ":~")
      else
        -- If there is no current directory (e.g. over ssh), just show the buffer name
        return vim.api.nvim_buf_get_name(0)
      end
    end

    require("oil").setup({
      -- Oil will take over directory buffers (e.g. `vim .` or `:e src/`)
      default_file_explorer = false, -- Keep neo-tree as default, oil as secondary

      -- Columns to display
      columns = {
        "icon",
      },

      -- Buffer-local options for oil buffers
      buf_options = {
        buflisted = false,
        bufhidden = "hide",
      },

      -- Window-local options for oil buffers
      win_options = {
        wrap = false,
        signcolumn = "no",
        cursorcolumn = false,
        foldcolumn = "0",
        spell = false,
        list = false,
        conceallevel = 3,
        concealcursor = "nvic",
        winbar = "%!v:lua.get_oil_winbar()",
      },

      -- Delete files to trash instead of permanently deleting
      delete_to_trash = true,

      -- Skip confirmation for simple operations
      skip_confirm_for_simple_edits = false,

      -- Prompt for confirmation before certain destructive operations
      prompt_save_on_select_new_entry = true,

      -- Cleanup empty directories
      cleanup_delay_ms = 2000,

      -- Set to false to disable all LSP features (improves performance)
      lsp_file_methods = {
        timeout_ms = 1000,
        autosave_changes = false,
      },

      -- Constrain cursor to first column
      constrain_cursor = "editable",

      -- Watch for changes
      watch_for_changes = false,

      -- Show hidden files and directories
      view_options = {
        show_hidden = true, -- Consistent with neo-tree setup
        is_hidden_file = function(name, bufnr)
          return vim.startswith(name, ".")
        end,
        is_always_hidden = function(name, bufnr)
          return false
        end,
        sort = {
          { "type", "asc" },
          { "name", "asc" },
        },
      },

      -- Keymaps in oil buffer
      keymaps = {
        ["g?"] = "actions.show_help",
        ["<CR>"] = "actions.select",
        ["<C-s>"] = "actions.select_vsplit",
        ["<C-h>"] = false, -- Disable to use window navigation
        ["<C-t>"] = "actions.select_tab",
        ["<C-p>"] = "actions.preview",
        ["<C-c>"] = "actions.close",
        ["<C-l>"] = false, -- Disable to use window navigation
        ["<C-r>"] = "actions.refresh",
        ["-"] = "actions.parent",
        ["_"] = "actions.open_cwd",
        ["`"] = "actions.cd",
        ["~"] = "actions.tcd",
        ["gs"] = "actions.change_sort",
        ["gx"] = "actions.open_external",
        ["g."] = "actions.toggle_hidden",
        ["g\\"] = "actions.toggle_trash",
      },

      -- Set to false to disable preview entirely
      use_default_keymaps = true,

      -- Configuration for the floating window
      float = {
        padding = 2,
        max_width = 0,
        max_height = 0,
        border = "rounded",
        win_options = {
          winblend = 0,
        },
        override = function(conf)
          return conf
        end,
      },

      -- Configuration for the actions floating preview window
      preview = {
        max_width = 0.9,
        min_width = { 40, 0.4 },
        width = nil,
        max_height = 0.9,
        min_height = { 5, 0.1 },
        height = nil,
        border = "rounded",
        win_options = {
          winblend = 0,
        },
      },

      -- Configuration for the floating progress window
      progress = {
        max_width = 0.9,
        min_width = { 40, 0.4 },
        width = nil,
        max_height = { 10, 0.9 },
        min_height = { 5, 0.1 },
        height = nil,
        border = "rounded",
        minimized_border = "none",
        win_options = {
          winblend = 0,
        },
      },
    })

    -- Window navigation keymaps (consistent with neo-tree)
    vim.keymap.set("n", "<C-h>", "<C-w>h", { noremap = true, silent = true })
    vim.keymap.set("n", "<C-j>", "<C-w>j", { noremap = true, silent = true })
    vim.keymap.set("n", "<C-k>", "<C-w>k", { noremap = true, silent = true })
    vim.keymap.set("n", "<C-l>", "<C-w>l", { noremap = true, silent = true })
  end,
}
