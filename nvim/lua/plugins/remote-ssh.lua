return {
  {
    "inhesrom/remote-ssh.nvim",
    branch = "master",
    dependencies = {
      "inhesrom/telescope-remote-buffer",
      "nvim-telescope/telescope.nvim",
      "nvim-lua/plenary.nvim",
      "neovim/nvim-lspconfig",
      "rcarriga/nvim-notify",
    },
    cmd = {
      "RemoteOpen",
      "RemoteTreeBrowser",
      "RemoteTreeBrowserHide",
      "RemoteTreeBrowserShow",
      "RemoteTui",
      "RemoteHistory",
      "RemoteGrep",
      "RemoteRefresh",
      "RemoteRefreshAll",
      "RemoteTerminalNew",
      "RemoteTerminalToggle",
      "RemoteTerminalClose",
      "RemoteTerminalRename",
      "RemoteSession",
      "RemoteSessionPicker",
      "RemoteSessionMinimize",
      "RemoteSessionRestore",
      "RemoteSessionClose",
      "RemoteDependencyCheck",
      "RemoteDependencyQuickCheck",
      "RemoteSSHLog",
    },
    keys = {
      { "<leader>ro", ":RemoteOpen rsync://", desc = "Remote SSH open" },
      { "<leader>rt", ":RemoteTreeBrowser rsync://", desc = "Remote SSH tree" },
      { "<leader>rs", ":RemoteSession ", desc = "Remote SSH session" },
      { "<leader>rp", "<cmd>RemoteSessionPicker<cr>", desc = "Remote SSH sessions" },
      { "<leader>rT", "<cmd>RemoteTerminalNew<cr>", desc = "Remote SSH terminal" },
      { "<leader>rl", "<cmd>RemoteSSHLog<cr>", desc = "Remote SSH log" },
      { "<leader>rd", "<cmd>RemoteDependencyQuickCheck<cr>", desc = "Remote SSH dependency check" },
    },
    config = function()
      require("telescope-remote-buffer").setup({
        fzf = "<leader>rz",
        match = "<leader>rb",
        oldfiles = "<leader>rr",
      })

      local capabilities = vim.lsp.protocol.make_client_capabilities()
      local ok, cmp_nvim_lsp = pcall(require, "cmp_nvim_lsp")
      if ok then
        capabilities = cmp_nvim_lsp.default_capabilities(capabilities)
      end

      require("remote-ssh").setup({
        capabilities = capabilities,
        filetype_to_server = {
          c = "clangd",
          cpp = "clangd",
          cmake = "cmake",
          go = "gopls",
          java = "jdtls",
          javascript = "ts_ls",
          javascriptreact = "ts_ls",
          lua = "lua_ls",
          python = "pyright",
          rust = "rust_analyzer",
          sh = "bashls",
          typescript = "ts_ls",
          typescriptreact = "ts_ls",
          xml = "lemminx",
          zig = "zls",
        },
        async_write_opts = {
          autosave = false,
          save_debounce_ms = 3000,
        },
      })
    end,
  },
}
