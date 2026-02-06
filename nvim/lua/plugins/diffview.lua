-- Plugin: Diffview
-- Description: Side-by-side git diff viewer. Compare changes, view file history, and manage git operations visually.
-- Commands: :DiffviewOpen, :DiffviewFileHistory

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
          local start = vim.loop.hrtime()
          vim.cmd("DiffviewOpen")
          local elapsed = (vim.loop.hrtime() - start) / 1e6
          -- Below print command for debugging time took
          -- print(string.format("DiffviewOpen took %.2f ms", elapsed))
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
    -- Quick HEAD~n comparisons
    { "<leader>d1", "<cmd>DiffviewOpen HEAD~1<cr>", desc = "Diff with HEAD~1" },
    { "<leader>d2", "<cmd>DiffviewOpen HEAD~2<cr>", desc = "Diff with HEAD~2" },
    { "<leader>d3", "<cmd>DiffviewOpen HEAD~3<cr>", desc = "Diff with HEAD~3" },
    { "<leader>d4", "<cmd>DiffviewOpen HEAD~4<cr>", desc = "Diff with HEAD~4" },
    { "<leader>d5", "<cmd>DiffviewOpen HEAD~5<cr>", desc = "Diff with HEAD~5" },
    { "<leader>d6", "<cmd>DiffviewOpen HEAD~6<cr>", desc = "Diff with HEAD~6" },
    { "<leader>d7", "<cmd>DiffviewOpen HEAD~7<cr>", desc = "Diff with HEAD~7" },
    { "<leader>d8", "<cmd>DiffviewOpen HEAD~8<cr>", desc = "Diff with HEAD~8" },
    { "<leader>d9", "<cmd>DiffviewOpen HEAD~9<cr>", desc = "Diff with HEAD~9" },
    { "<leader>d0", "<cmd>DiffviewOpen HEAD~10<cr>", desc = "Diff with HEAD~10" },
    -- Note: <leader>dm, <leader>db, <leader>d2b, <leader>dq are provided by diff-utils.lua
  },
  config = function()
    local actions = require("diffview.actions")

    -- Store keymaps configuration for help panel
    local keymaps_config = {}

    -- Custom action: Go to file at cursor position, return to previous window, and close diffview
    local function goto_file_and_close()
      local lib = require("diffview.lib")
      local view = lib.get_current_view()
      if not view then return end

      -- Get the file path and cursor position
      local file = view:infer_cur_file()
      if not file then return end

      local cursor = vim.api.nvim_win_get_cursor(0)
      local filepath = file.absolute_path or file.path

      -- Find the previous non-diffview tabpage
      local target_tab = lib.get_prev_non_view_tabpage()

      -- Close diffview first
      vim.cmd("DiffviewClose")

      -- Go to the previous tabpage if it exists
      if target_tab then
        vim.api.nvim_set_current_tabpage(target_tab)
      end

      -- Open the file in the current window
      vim.cmd("edit " .. vim.fn.fnameescape(filepath))

      -- Set cursor to the line we were viewing in the diff
      vim.api.nvim_win_set_cursor(0, cursor)
    end

    require("diffview").setup({
      diff_binaries = false,
      enhanced_diff_hl = false, -- Disable character-level diff highlighting (too noisy with numbers)
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
        listing_style = "list",
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
        diff_buf_read = function(bufnr)
          -- Change local options in diff buffers
          vim.opt_local.wrap = false
          vim.opt_local.list = false
          vim.opt_local.colorcolumn = { 80 }

          -- Disable inlay hints in diff buffers (too noisy)
          vim.lsp.inlay_hint.enable(false, { bufnr = bufnr })
        end,

        diff_buf_win_enter = function(bufnr, winid, ctx)
          -- Make right pane (working tree) wider than left pane (old version)
          if ctx.layout_name == "diff2_horizontal" then
            local total_width = vim.o.columns - 35 -- Subtract file panel width

            if ctx.symbol == "a" then
              -- Left pane (old version): 40% of diff area
              vim.api.nvim_win_set_width(winid, math.floor(total_width * 0.4))
            elseif ctx.symbol == "b" then
              -- Right pane (new/working tree): 60% of diff area
              vim.api.nvim_win_set_width(winid, math.floor(total_width * 0.6))
            end
          end
        end,
      },

      keymaps = {
        disable_defaults = true,
        view = {
          { "n", "<tab>", actions.select_next_entry, { desc = "Next file" } },
          { "n", "<s-tab>", actions.select_prev_entry, { desc = "Previous file" } },
          { "n", "gf", goto_file_and_close, { desc = "Go to file and close diffview" } },
          { "n", "<CR>", actions.select_entry, { desc = "Select entry" } },
          { "n", "<leader>b", actions.toggle_files, { desc = "Toggle file panel" } },
          { "n", "g<C-x>", actions.cycle_layout, { desc = "Cycle layout" } },
          { "n", "g?", actions.help({ "view" }), { desc = "Help" } },
          -- Window navigation (consistent with Oil and NeoTree)
          { "n", "<C-h>", "<C-w>h", { desc = "Navigate to left window" } },
          { "n", "<C-j>", "<C-w>j", { desc = "Navigate to bottom window" } },
          { "n", "<C-k>", "<C-w>k", { desc = "Navigate to top window" } },
          { "n", "<C-l>", "<C-w>l", { desc = "Navigate to right window" } },
        },
        diff1 = {
          { "n", "g?", actions.help({ "view", "diff1" }), { desc = "Help" } },
        },
        diff2 = {
          { "n", "g?", actions.help({ "view", "diff2" }), { desc = "Help" } },
        },
        diff3 = {
          { "n", "1o", actions.diffget("ours"), { desc = "Obtain ours" } },
          { "n", "2o", actions.diffget("theirs"), { desc = "Obtain theirs" } },
          { "n", "3o", actions.diffget("base"), { desc = "Obtain base" } },
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
          { "n", "gf", goto_file_and_close, { desc = "Go to file and close diffview" } },

          -- Git staging operations
          {
            "n",
            "a",
            function()
              local ok, err = pcall(actions.toggle_stage_entry)
              if not ok then
                -- Log detailed error to file
                local log_file = vim.fn.stdpath("cache") .. "/diffview-errors.log"
                local timestamp = os.date("%Y-%m-%d %H:%M:%S")
                local log_entry = string.format("[%s] %s\n", timestamp, tostring(err))

                local f = io.open(log_file, "a")
                if f then
                  f:write(log_entry)
                  f:close()
                end

                -- Show clean error message with log location
                vim.notify(
                  string.format("Error staging file. See %s for details.", log_file),
                  vim.log.levels.ERROR
                )
              end
            end,
            { desc = "Stage/unstage file" },
          },
          { "n", "U", actions.unstage_all, { desc = "Unstage all changes" } },

          -- View controls
          { "n", "i", actions.listing_style, { desc = "Toggle list/tree" } },
          { "n", "f", actions.toggle_flatten_dirs, { desc = "Flatten dirs" } },
          { "n", "R", actions.refresh_files, { desc = "Refresh" } },
          { "n", "<leader>b", actions.toggle_files, { desc = "Toggle panel" } },
          { "n", "g<C-x>", actions.cycle_layout, { desc = "Cycle layout" } },
          { "n", "g?", actions.help("file_panel"), { desc = "Help" } },
          -- Window navigation (consistent with Oil and NeoTree)
          { "n", "<C-h>", "<C-w>h", { desc = "Navigate to left window" } },
          { "n", "<C-j>", "<C-w>j", { desc = "Navigate to bottom window" } },
          { "n", "<C-k>", "<C-w>k", { desc = "Navigate to top window" } },
          { "n", "<C-l>", "<C-w>l", { desc = "Navigate to right window" } },
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
          { "n", "gf", goto_file_and_close, { desc = "Go to file and close diffview" } },

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
          -- Window navigation (consistent with Oil and NeoTree)
          { "n", "<C-h>", "<C-w>h", { desc = "Navigate to left window" } },
          { "n", "<C-j>", "<C-w>j", { desc = "Navigate to bottom window" } },
          { "n", "<C-k>", "<C-w>k", { desc = "Navigate to top window" } },
          { "n", "<C-l>", "<C-w>l", { desc = "Navigate to right window" } },
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
