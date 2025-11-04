-- Plugin: ts-context-commentstring
-- Description: Treesitter-aware comment detection for JSX/TSX files.
--              Automatically uses {/* */} for JSX and // for JavaScript based on cursor context.

return {
  "JoosepAlviste/nvim-ts-context-commentstring",
  dependencies = "nvim-treesitter/nvim-treesitter",
  event = { "BufReadPre", "BufNewFile" },
  config = function()
    require("ts_context_commentstring").setup({
      enable_autocmd = false, -- Let mini.comment handle this
    })
  end,
}
