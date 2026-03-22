-- Plugin: LeetCode.nvim
-- Description: Solve LeetCode problems directly in Neovim
-- Keybindings: <leader>lq (menu), <leader>lr (run), <leader>ls (submit), <leader>lc (change language)

return {
  "kawre/leetcode.nvim",
  build = ":TSUpdate html",
  dependencies = {
    "nvim-telescope/telescope.nvim",
    "nvim-lua/plenary.nvim",
    "MunifTanjim/nui.nvim",
    "nvim-treesitter/nvim-treesitter",
    "nvim-tree/nvim-web-devicons",
  },
  opts = {
    arg = "leetcode.nvim",
    lang = "typescript", -- Default language (can be changed with :Leet lang)
    cn = { enabled = false }, -- Use LeetCode.com (not .cn)

    storage = {
      home = vim.fn.expand("~/leetcode"),
      cache = vim.fn.stdpath("cache") .. "/leetcode",
    },

    plugins = {
      non_standalone = false,
    },

    logging = true,
    injector = {},

    cache = {
      update_interval = 60 * 60 * 24 * 7, -- Update cache every 7 days
    },

    console = {
      open_on_runcode = true,
      dir = "row",
      size = { width = "90%", height = "75%" },
      result = { size = "60%" },
      testcase = {
        virt_text = true,
        size = "40%",
      },
    },

    description = {
      position = "left",
      width = "40%",
      show_stats = true,
    },

    hooks = {
      ["enter"] = {},
      ["question_enter"] = {},
      ["leave"] = {},
    },

    keys = {
      toggle = { "q" },
      confirm = { "<CR>" },
      reset_testcases = "r",
      use_testcase = "U",
      focus_testcases = "H",
      focus_result = "L",
    },

    theme = {},
    image_support = false,
  },

  keys = {
    -- Core commands
    { "<leader>lq", "<cmd>Leet<cr>", desc = "LeetCode: Open menu" },
    { "<leader>lr", "<cmd>Leet run<cr>", desc = "LeetCode: Run code" },
    { "<leader>ls", "<cmd>Leet submit<cr>", desc = "LeetCode: Submit solution" },
    { "<leader>lt", "<cmd>Leet test<cr>", desc = "LeetCode: Run test" },

    -- Navigation
    { "<leader>ll", "<cmd>Leet list<cr>", desc = "LeetCode: Problem list" },
    { "<leader>ld", "<cmd>Leet daily<cr>", desc = "LeetCode: Daily challenge" },
    { "<leader>lR", "<cmd>Leet random<cr>", desc = "LeetCode: Random problem" },
    { "<leader>lo", "<cmd>Leet open<cr>", desc = "LeetCode: Open in browser" },

    -- Configuration
    { "<leader>lc", "<cmd>Leet lang<cr>", desc = "LeetCode: Change language" },
    { "<leader>li", "<cmd>Leet info<cr>", desc = "LeetCode: Show info" },
    { "<leader>lD", "<cmd>Leet desc toggle<cr>", desc = "LeetCode: Toggle description" },

    -- Utilities
    { "<leader>ly", "<cmd>Leet yank<cr>", desc = "LeetCode: Yank solution" },
    { "<leader>lx", "<cmd>Leet reset<cr>", desc = "LeetCode: Reset code" },
    { "<leader>lC", "<cmd>Leet console<cr>", desc = "LeetCode: Open console" },
  },
}
