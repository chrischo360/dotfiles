-- Plugin: nvim-ts-autotag
-- Description: Auto-closes and renames HTML/JSX tags automatically using treesitter.
--              When you type <div>, it auto-adds </div>. When you rename opening tag, it renames closing tag.

return {
  "windwp/nvim-ts-autotag",
  dependencies = "nvim-treesitter/nvim-treesitter",
  event = { "BufReadPre", "BufNewFile" },
  config = function()
    require("nvim-ts-autotag").setup({
      enable = true,
      filetypes = {
        "html",
        "javascript",
        "typescript",
        "javascriptreact",
        "typescriptreact",
        "svelte",
        "vue",
        "tsx",
        "jsx",
        "xml",
        "php",
        "markdown",
      },
    })
  end,
}
