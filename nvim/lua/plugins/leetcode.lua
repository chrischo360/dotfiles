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
    "3rd/image.nvim",
  },
  cmd = "Leet",
  opts = {
    lang = "python3", -- Default language (can be changed with :Leet lang)
    cn = { enabled = false }, -- Use LeetCode.com (not .cn)

    storage = {
      home = vim.fn.expand("~/leetcode"),
      cache = vim.fn.stdpath("cache") .. "/leetcode",
    },

    plugins = {
      non_standalone = true,
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
      ["enter"] = {
        function()
          vim.keymap.set("n", "<C-h>", "<C-w>h", { noremap = true, silent = true })
          vim.keymap.set("n", "<C-l>", "<C-w>l", { noremap = true, silent = true })
        end,
      },
      ["question_enter"] = {
        -- Fix Rust LSP by generating rust-project.json
        function()
          local file_extension = vim.fn.expand("%:e")
          if file_extension == "rs" then
            local leetcode_dir = vim.fn.stdpath("data") .. "/leetcode"

            -- Get sysroot path
            local handle = io.popen("rustc --print sysroot")
            local sysroot = handle:read("*a"):gsub("%s+", "")
            handle:close()
            local sysroot_src = sysroot .. "/lib/rustlib/src/rust/library"

            -- Find all .rs files in the leetcode directory
            local rs_files = vim.fn.glob(leetcode_dir .. "/*.rs", false, true)
            local crates = {}

            for _, file in ipairs(rs_files) do
              local filename = vim.fn.fnamemodify(file, ":t")
              table.insert(crates, {
                root_module = filename,
                edition = "2021",
                deps = {},
              })
            end

            -- Generate rust-project.json
            local rust_project = {
              sysroot_src = sysroot_src,
              crates = crates,
            }

            local json_file = leetcode_dir .. "/rust-project.json"
            local f = io.open(json_file, "w")
            if f then
              f:write(vim.fn.json_encode(rust_project))
              f:close()

              -- Restart rust_analyzer LSP if it's attached
              vim.defer_fn(function()
                for _, client in ipairs(vim.lsp.get_clients({ bufnr = 0 })) do
                  if client.name == "rust_analyzer" then
                    vim.cmd("LspRestart rust_analyzer")
                    break
                  end
                end
              end, 100)
            end
          end
        end,
      },
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
    image_support = true,
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
