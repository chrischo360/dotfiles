-- Plugin: Git Extras (vim-fugitive + gitsigns)
-- Description: Git integration showing line changes in gutter, git blame, and hunk navigation.
--              Fugitive provides :Git commands, gitsigns shows inline changes.
-- Keybindings: ]c (next hunk), [c (prev hunk), <leader>hb (blame line)

return {
  -- Git blame with custom formatting
  {
    "FabijanZulj/blame.nvim",
    cmd = { "BlameToggle" },
    keys = {
      { "<leader>gb", "<cmd>BlameToggle<cr>", desc = "Git Blame" },
    },
    opts = {
      date_format = "%Y-%m-%d",
      virtual_style = "float",
      merge_consecutive = false,
      max_summary_width = 30,
      commit_detail_view = "vsplit",
      mappings = {
        commit_info = "i",
        stack_push = "<TAB>",
        stack_pop = "<BS>",
        show_commit = "<CR>",
        close = { "<esc>", "q" },
      },
      format = function(line_porcelain, config, idx)
        local author = line_porcelain.author
        local date = line_porcelain.author_time
        local summary = line_porcelain.summary

        -- Convert timestamp to relative format
        local now = os.time()
        local diff = now - tonumber(date)
        local relative_date

        if diff < 60 then
          relative_date = "now"
        elseif diff < 3600 then
          relative_date = math.floor(diff / 60) .. "m ago"
        elseif diff < 86400 then
          relative_date = math.floor(diff / 3600) .. "h ago"
        elseif diff < 604800 then
          relative_date = math.floor(diff / 86400) .. "d ago"
        elseif diff < 2592000 then
          relative_date = math.floor(diff / 604800) .. "w ago"
        elseif diff < 31536000 then
          relative_date = math.floor(diff / 2592000) .. "mo ago"
        else
          relative_date = math.floor(diff / 31536000) .. "y ago"
        end

        return string.format("%s • %s • %s", summary, relative_date, author)
      end,
    },
  },

  -- Git commands (status, etc.)
  {
    "tpope/vim-fugitive",
    cmd = { "Git", "Gstatus", "Gpush", "Gpull", "Gdiff" },
    keys = {
      { "<leader>gs", "<cmd>Git<cr>", desc = "Git Status" },
    },
  },

  -- Git signs for buffer
  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      signs = {
        add = { text = "┃" },
        change = { text = "┃" },
        delete = { text = "_" },
        topdelete = { text = "‾" },
        changedelete = { text = "~" },
        untracked = { text = "┆" },
      },
      signs_staged = {
        add = { text = "┃" },
        change = { text = "┃" },
        delete = { text = "_" },
        topdelete = { text = "‾" },
        changedelete = { text = "~" },
        untracked = { text = "┆" },
      },
      signcolumn = true,
      numhl = false,
      linehl = false,
      word_diff = false,
      watch_gitdir = {
        follow_files = true,
      },
      attach_to_untracked = true,
      current_line_blame = false, -- Disabled by default for performance (toggle with <leader>tb)
      current_line_blame_opts = {
        virt_text = true,
        virt_text_pos = "eol",
        delay = 1000,
        ignore_whitespace = false,
        virt_text_priority = 100,
      },
      current_line_blame_formatter = '<author>, <author_time:%R> - <summary>',
      sign_priority = 6,
      update_debounce = 100,
      status_formatter = nil,
      max_file_length = 40000,
      preview_config = {
        border = "single",
        style = "minimal",
        relative = "cursor",
        row = 0,
        col = 1,
      },
      on_attach = function(bufnr)
        local gs = package.loaded.gitsigns

        local function map(mode, l, r, opts)
          opts = opts or {}
          opts.buffer = bufnr
          vim.keymap.set(mode, l, r, opts)
        end

        -- Navigation
        map("n", "]c", function()
          if vim.wo.diff then
            return "]c"
          end
          vim.schedule(function()
            gs.next_hunk()
          end)
          return "<Ignore>"
        end, { expr = true, desc = "Next Git Hunk" })

        map("n", "[c", function()
          if vim.wo.diff then
            return "[c"
          end
          vim.schedule(function()
            gs.prev_hunk()
          end)
          return "<Ignore>"
        end, { expr = true, desc = "Previous Git Hunk" })

        -- Actions
        map("n", "<leader>hs", gs.stage_hunk, { desc = "Stage Hunk" })
        map("n", "<leader>hr", gs.reset_hunk, { desc = "Reset Hunk" })
        map("v", "<leader>hs", function()
          gs.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
        end, { desc = "Stage Hunk" })
        map("v", "<leader>hr", function()
          gs.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
        end, { desc = "Reset Hunk" })
        map("n", "<leader>hS", gs.stage_buffer, { desc = "Stage Buffer" })
        map("n", "<leader>hu", gs.undo_stage_hunk, { desc = "Undo Stage Hunk" })
        map("n", "<leader>hR", gs.reset_buffer, { desc = "Reset Buffer" })
        map("n", "<leader>hp", gs.preview_hunk, { desc = "Preview Hunk" })
        map("n", "<leader>hb", function()
          gs.blame_line({ full = true })
        end, { desc = "Blame Line" })
        map("n", "<leader>tb", gs.toggle_current_line_blame, { desc = "Toggle Line Blame" })
        map("n", "<leader>hd", gs.diffthis, { desc = "Diff This" })
        map("n", "<leader>hD", function()
          gs.diffthis("~")
        end, { desc = "Diff This ~" })
        map("n", "<leader>td", gs.toggle_deleted, { desc = "Toggle Deleted" })

        -- Text object
        map({ "o", "x" }, "ih", ":<C-U>Gitsigns select_hunk<CR>", { desc = "Select Git Hunk" })
      end,
    },
  },

  -- Advanced git log and branch viewer
  {
    "junegunn/gv.vim",
    dependencies = { "tpope/vim-fugitive" },
    cmd = { "GV" },
    keys = {
      { "<leader>gv", "<cmd>GV<cr>", desc = "Git Log" },
      { "<leader>gV", "<cmd>GV!<cr>", desc = "Git Log (current file)" },
    },
  },
}
