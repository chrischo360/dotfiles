return {
  "sindrets/diffview.nvim",
  dependencies = { "nvim-lua/plenary.nvim" },
  cmd = {
    "DiffviewOpen",
    "DiffviewClose",
    "DiffviewToggle",
    "DiffviewFileHistory",
    "DiffviewRefresh",
  },
  keys = {
    -- Toggle diffview (shows uncommitted changes by default)
    {
      "<leader>dv",
      function()
        if next(require("diffview.lib").views) == nil then
          vim.cmd("DiffviewOpen")
        else
          vim.cmd("DiffviewClose")
        end
      end,
      desc = "Toggle Diffview (uncommitted changes)",
    },
    -- File history
    {
      "<leader>dfh",
      "<cmd>DiffviewFileHistory %<cr>",
      desc = "File History (current file)",
    },
    {
      "<leader>dfa",
      "<cmd>DiffviewFileHistory<cr>",
      desc = "File History (all files)",
    },
    -- Note: <leader>dm, <leader>db, <leader>d2, <leader>dq are provided by diff-utils.lua
  },
  config = function()
    local actions = require("diffview.actions")

    require("diffview").setup({
      diff_binaries = false,
      enhanced_diff_hl = true,
      git_cmd = { "git" },
      use_icons = true,
      show_help_hints = true,
      watch_index = true,

      icons = {
        folder_closed = "",
        folder_open = "",
      },

      signs = {
        fold_closed = "",
        fold_open = "",
        done = "✓",
      },

      view = {
        default = {
          layout = "diff2_horizontal",
          winbar_info = true,
        },
        merge_tool = {
          layout = "diff3_horizontal",
          disable_diagnostics = true,
          winbar_info = true,
        },
        file_history = {
          layout = "diff2_horizontal",
          winbar_info = true,
        },
      },

      file_panel = {
        listing_style = "tree",
        tree_options = {
          flatten_dirs = true,
          folder_statuses = "only_folded",
        },
        win_config = {
          position = "left",
          width = 35,
          win_opts = {},
        },
      },

      file_history_panel = {
        log_options = {
          git = {
            single_file = {
              diff_merges = "combined",
            },
            multi_file = {
              diff_merges = "first-parent",
            },
          },
        },
        win_config = {
          position = "bottom",
          height = 16,
          win_opts = {},
        },
      },

      commit_log_panel = {
        win_config = {
          position = "bottom",
          height = 16,
          win_opts = {},
        },
      },

      default_args = {
        DiffviewOpen = {},
        DiffviewFileHistory = {},
      },

      hooks = {
        diff_buf_read = function()
          -- Change local options in diff buffers
          vim.opt_local.wrap = false
          vim.opt_local.list = false
          vim.opt_local.colorcolumn = { 80 }
        end,
      },

      keymaps = {
        disable_defaults = true,
        view = {
          { "n", "<tab>", actions.select_next_entry, { desc = "Next file" } },
          { "n", "<s-tab>", actions.select_prev_entry, { desc = "Previous file" } },
          { "n", "gf", actions.goto_file, { desc = "Open file in buffer" } },
          { "n", "<leader>b", actions.toggle_files, { desc = "Toggle file panel" } },
          { "n", "g<C-x>", actions.cycle_layout, { desc = "Cycle layout" } },
          { "n", "g?", actions.help({ "view" }), { desc = "Help" } },
        },
        diff1 = {
          { "n", "g?", actions.help({ "view", "diff1" }), { desc = "Help" } },
        },
        diff2 = {
          { "n", "g?", actions.help({ "view", "diff2" }), { desc = "Help" } },
        },
        diff3 = {
          { "n", "g?", actions.help({ "view", "diff3" }), { desc = "Help" } },
        },
        diff4 = {
          { "n", "g?", actions.help({ "view", "diff4" }), { desc = "Help" } },
        },
        file_panel = {
          -- Navigation
          { "n", "j", actions.next_entry, { desc = "Next file" } },
          { "n", "k", actions.prev_entry, { desc = "Previous file" } },
          { "n", "<down>", actions.next_entry, { desc = "Next file" } },
          { "n", "<up>", actions.prev_entry, { desc = "Previous file" } },
          { "n", "<tab>", actions.select_next_entry, { desc = "Next file (open)" } },
          { "n", "<s-tab>", actions.select_prev_entry, { desc = "Previous file (open)" } },
          { "n", "<cr>", actions.select_entry, { desc = "Open diff" } },
          { "n", "<2-LeftMouse>", actions.select_entry, { desc = "Open diff" } },

          -- File operations
          { "n", "gf", actions.goto_file, { desc = "Open file in buffer" } },

          -- View controls
          { "n", "i", actions.listing_style, { desc = "Toggle list/tree" } },
          { "n", "f", actions.toggle_flatten_dirs, { desc = "Flatten dirs" } },
          { "n", "R", actions.refresh_files, { desc = "Refresh" } },
          { "n", "<leader>b", actions.toggle_files, { desc = "Toggle panel" } },
          { "n", "g<C-x>", actions.cycle_layout, { desc = "Cycle layout" } },
          { "n", "g?", actions.help("file_panel"), { desc = "Help" } },
        },
        file_history_panel = {
          -- Navigation
          { "n", "j", actions.next_entry, { desc = "Next commit" } },
          { "n", "k", actions.prev_entry, { desc = "Previous commit" } },
          { "n", "<down>", actions.next_entry, { desc = "Next commit" } },
          { "n", "<up>", actions.prev_entry, { desc = "Previous commit" } },
          { "n", "<tab>", actions.select_next_entry, { desc = "Next commit (open)" } },
          { "n", "<s-tab>", actions.select_prev_entry, { desc = "Previous commit (open)" } },
          { "n", "<cr>", actions.select_entry, { desc = "Open diff" } },
          { "n", "<2-LeftMouse>", actions.select_entry, { desc = "Open diff" } },

          -- File operations
          { "n", "gf", actions.goto_file, { desc = "Open file in buffer" } },

          -- Git operations
          { "n", "y", actions.copy_hash, { desc = "Copy commit hash" } },
          { "n", "L", actions.open_commit_log, { desc = "Commit details" } },

          -- Folding
          { "n", "zR", actions.open_all_folds, { desc = "Expand all" } },
          { "n", "zM", actions.close_all_folds, { desc = "Collapse all" } },

          -- View controls
          { "n", "g!", actions.options, { desc = "Options" } },
          { "n", "<leader>b", actions.toggle_files, { desc = "Toggle panel" } },
          { "n", "g<C-x>", actions.cycle_layout, { desc = "Cycle layout" } },
          { "n", "g?", actions.help("file_history_panel"), { desc = "Help" } },
        },
        option_panel = {
          { "n", "<tab>", actions.select_entry, { desc = "Change option" } },
          { "n", "q", actions.close, { desc = "Close" } },
          { "n", "g?", actions.help("option_panel"), { desc = "Help" } },
        },
        help_panel = {
          { "n", "q", actions.close, { desc = "Close" } },
          { "n", "<esc>", actions.close, { desc = "Close" } },
        },
      },
    })

    -- Setup advanced diff utilities
    local diff_utils = require("utils.diff-utils")
    diff_utils.setup_keymaps()
  end,
}
