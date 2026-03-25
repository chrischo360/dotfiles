return {
  "pwntester/octo.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-telescope/telescope.nvim",
    "nvim-tree/nvim-web-devicons",
  },
  cmd = "Octo",
  keys = {
    -- Quick Access (Octo prefix)
    {
      "<leader>Oo",
      function()
        vim.cmd("Octo")
      end,
      desc = "Octo commands",
    },
    {
      "<leader>Op",
      function()
        vim.cmd("Octo pr list")
      end,
      desc = "PR list",
    },
    {
      "<leader>Oi",
      function()
        vim.cmd("Octo issue list")
      end,
      desc = "Issue list",
    },
    {
      "<leader>On",
      function()
        vim.cmd("Octo notifications")
      end,
      desc = "Notifications",
    },
    {
      "<leader>Os",
      function()
        vim.cmd("Octo search")
      end,
      desc = "Search PRs/issues",
    },

    -- Current PR/Issue
    {
      "<leader>Ov",
      function()
        vim.cmd("Octo pr")
      end,
      desc = "View current PR",
    },
    {
      "<leader>Od",
      function()
        vim.cmd("Octo pr diff")
      end,
      desc = "PR diff",
    },
    {
      "<leader>Oc",
      function()
        vim.cmd("Octo pr checks")
      end,
      desc = "PR checks/CI status",
    },
    {
      "<leader>Or",
      function()
        vim.cmd("Octo review start")
      end,
      desc = "Start review",
    },
    {
      "<leader>OR",
      function()
        vim.cmd("Octo review resume")
      end,
      desc = "Resume review",
    },
    {
      "<leader>Ou",
      function()
        vim.cmd("!gh pr merge --update-branch")
      end,
      desc = "Update PR branch",
    },
  },
  config = function()
    require("octo").setup({
      picker = "telescope",
      enable_builtin = true,
      default_merge_method = "squash",
      use_local_fs = true,

      poll = {
        enabled = true,
        interval = 60000, -- Poll every 60 seconds (1 minute)
        notify_on_refresh = true,
        notify_on_change = true,
      },

      reviews = {
        auto_show_threads = true,
      },

      suppress_missing_scope = {
        projects_v2 = true,
      },

      mappings = {
        review_diff = {
          next_thread = { lhs = "]t", desc = "move to next thread" },
          prev_thread = { lhs = "[t", desc = "move to previous thread" },
          select_next_entry = { lhs = "]q", desc = "move to next changed file" },
          select_prev_entry = { lhs = "[q", desc = "move to previous changed file" },
          add_comment = { lhs = "<space>ca", desc = "add a new comment" },
          add_suggestion = { lhs = "<space>sa", desc = "add a new suggestion" },
          approve_review = { lhs = "<C-a>", desc = "approve review" },
          comment_review = { lhs = "<C-m>", desc = "comment review" },
          request_changes = { lhs = "<C-r>", desc = "request changes review" },
          toggle_viewed = { lhs = "<leader><space>", desc = "toggle viewer viewed state" },
        },
        review_thread = {
          next_comment = { lhs = "]c", desc = "move to next comment" },
          prev_comment = { lhs = "[c", desc = "move to previous comment" },
          add_comment = { lhs = "<space>ca", desc = "add comment" },
          add_suggestion = { lhs = "<space>sa", desc = "add suggestion" },
        },
        file_panel = {
          next_entry = { lhs = "j", desc = "move to next changed file" },
          prev_entry = { lhs = "k", desc = "move to previous changed file" },
          select_entry = { lhs = "<cr>", desc = "show selected changed file diffs" },
          refresh_files = { lhs = "R", desc = "refresh changed files panel" },
          toggle_viewed = { lhs = "<leader><space>", desc = "toggle viewer viewed state" },
        },
      },
    })
  end,
}
