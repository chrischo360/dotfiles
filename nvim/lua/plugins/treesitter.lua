-- Plugin: nvim-treesitter
-- Description: Parser installer and query provider for treesitter-based features.
-- Note: On the main branch (Neovim 0.12+), highlighting/indent/injections are
--       handled by Neovim's built-in treesitter support, not the plugin.

local languages = {
  "lua",
  "vim",
  "javascript",
  "typescript",
  "tsx",
  "html",
  "css",
  "json",
  "markdown",
  "markdown_inline",
  "swift",
  "python",
  "php",
  "java",
  "rust",
  "bash",
  "svelte",
  "graphql",
}

return {
  "nvim-treesitter/nvim-treesitter",
  branch = "main",
  lazy = false,
  build = ":TSUpdate",
  config = function()
    require("nvim-treesitter").install(languages)

    vim.api.nvim_create_autocmd("FileType", {
      pattern = "*",
      callback = function()
        pcall(vim.treesitter.start)
      end,
    })
  end,
}
