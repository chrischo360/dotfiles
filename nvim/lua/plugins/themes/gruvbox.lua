-- Theme: Gruvbox
-- Description: Retro groove color scheme with warm, neutral colors.
-- Variants: gruvbox (dark), gruvbox-light

return {
  "morhetz/gruvbox",
  enabled = true,
  priority = 1000,
  init = function()
    vim.o.background = "light"  -- Set BEFORE colorscheme loads
  end,
  config = function()
    vim.cmd.colorscheme("gruvbox")

    -- Custom diff colors for better visibility in light mode
    vim.api.nvim_set_hl(0, "DiffAdd", { bg = "#d3f8ce", fg = "NONE" })
    vim.api.nvim_set_hl(0, "DiffDelete", { bg = "#ffe0e0", fg = "NONE" })
    vim.api.nvim_set_hl(0, "DiffChange", { bg = "#fff3bf", fg = "NONE" })
    vim.api.nvim_set_hl(0, "DiffText", { bg = "#ffd43b", fg = "#1a1a1a", bold = true })

    -- Markdown heading colors for render-markdown.nvim
    vim.api.nvim_set_hl(0, "RenderMarkdownH1Bg", { bg = "#a3e635", fg = "#1a1a1a", bold = true })
    vim.api.nvim_set_hl(0, "RenderMarkdownH2Bg", { bg = "#60a5fa", fg = "#1a1a1a", bold = true })
    vim.api.nvim_set_hl(0, "RenderMarkdownH3Bg", { bg = "#f87171", fg = "#1a1a1a", bold = true })
    vim.api.nvim_set_hl(0, "RenderMarkdownH4Bg", { bg = "#fb923c", fg = "#1a1a1a", bold = true })
    vim.api.nvim_set_hl(0, "RenderMarkdownH5Bg", { bg = "#2dd4bf", fg = "#1a1a1a", bold = true })
    vim.api.nvim_set_hl(0, "RenderMarkdownH6Bg", { bg = "#c084fc", fg = "#1a1a1a", bold = true })

    -- Checkbox colors
    vim.api.nvim_set_hl(0, "RenderMarkdownTodoUnchecked", { fg = "#0ea5e9" })
    vim.api.nvim_set_hl(0, "RenderMarkdownTodoChecked", { fg = "#22c55e", strikethrough = true })
  end,
}
