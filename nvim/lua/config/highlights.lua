-- Shared highlight overrides for all themes
-- These are applied after the colorscheme loads

local M = {}

-- Light theme highlights (gruvbox light, solarized light, etc.)
M.light = function()
  -- Diff colors - brighter for light backgrounds
  vim.api.nvim_set_hl(0, "DiffAdd", { bg = "#b8f5a6", fg = "#1a1a1a" })
  vim.api.nvim_set_hl(0, "DiffDelete", { bg = "#ffb3b3", fg = "#1a1a1a" })
  vim.api.nvim_set_hl(0, "DiffChange", { bg = "#ffe680", fg = "#1a1a1a" })
  vim.api.nvim_set_hl(0, "DiffText", { bg = "#ffd43b", fg = "#1a1a1a", bold = true })

  -- Git signs in gutter
  vim.api.nvim_set_hl(0, "GitSignsAdd", { fg = "#22aa22" })
  vim.api.nvim_set_hl(0, "GitSignsDelete", { fg = "#dd2222" })
  vim.api.nvim_set_hl(0, "GitSignsChange", { fg = "#f57e20" })

  -- Markdown headings - vibrant colors with dark text
  vim.api.nvim_set_hl(0, "RenderMarkdownH1Bg", { bg = "#a3e635", fg = "#1a1a1a", bold = true })
  vim.api.nvim_set_hl(0, "RenderMarkdownH2Bg", { bg = "#60a5fa", fg = "#1a1a1a", bold = true })
  vim.api.nvim_set_hl(0, "RenderMarkdownH3Bg", { bg = "#f87171", fg = "#1a1a1a", bold = true })
  vim.api.nvim_set_hl(0, "RenderMarkdownH4Bg", { bg = "#fb923c", fg = "#1a1a1a", bold = true })
  vim.api.nvim_set_hl(0, "RenderMarkdownH5Bg", { bg = "#2dd4bf", fg = "#1a1a1a", bold = true })
  vim.api.nvim_set_hl(0, "RenderMarkdownH6Bg", { bg = "#c084fc", fg = "#1a1a1a", bold = true })

  -- Markdown checkboxes
  vim.api.nvim_set_hl(0, "RenderMarkdownTodoUnchecked", { fg = "#0ea5e9" })
  vim.api.nvim_set_hl(0, "RenderMarkdownTodoChecked", { fg = "#22c55e", strikethrough = true })

  -- Additional diff highlights
  vim.api.nvim_set_hl(0, "DiffAdded", { fg = "#22aa22", bg = "#b8f5a6" })
  vim.api.nvim_set_hl(0, "DiffRemoved", { fg = "#dd2222", bg = "#ffb3b3" })
  vim.api.nvim_set_hl(0, "DiffLine", { fg = "#0369a1", bold = true })
  vim.api.nvim_set_hl(0, "DiffFile", { fg = "#7c3aed", bold = true })
end

-- Dark theme highlights (dracula, tokyonight, gruvbox dark, etc.)
M.dark = function()
  -- Diff colors - darker backgrounds with bright text
  vim.api.nvim_set_hl(0, "DiffAdd", { bg = "#1b3a2d", fg = "#7aa89f" })
  vim.api.nvim_set_hl(0, "DiffDelete", { bg = "#3a1a1a", fg = "#ff7979" })
  vim.api.nvim_set_hl(0, "DiffChange", { bg = "#3a3a1a", fg = "#ffdd66" })
  vim.api.nvim_set_hl(0, "DiffText", { bg = "#2d5a5a", fg = "#7dcfff", bold = true })

  -- Diffview.nvim specific
  vim.api.nvim_set_hl(0, "DiffviewDiffAdd", { bg = "#1b3a2d" })
  vim.api.nvim_set_hl(0, "DiffviewDiffDelete", { bg = "#3a1a1a" })
  vim.api.nvim_set_hl(0, "DiffviewDiffChange", { bg = "#3a3a1a" })
  vim.api.nvim_set_hl(0, "DiffviewDiffText", { bg = "#2d5a5a", fg = "#7dcfff", bold = true })

  -- Git signs in gutter
  vim.api.nvim_set_hl(0, "GitSignsAdd", { fg = "#9ece6a" })
  vim.api.nvim_set_hl(0, "GitSignsChange", { fg = "#ff9e64" })
  vim.api.nvim_set_hl(0, "GitSignsDelete", { fg = "#f7768e" })

  -- Git conflict highlights
  vim.api.nvim_set_hl(0, "GitConflictCurrent", { bg = "#1b3a2d" })
  vim.api.nvim_set_hl(0, "GitConflictIncoming", { bg = "#2d3a5a" })
  vim.api.nvim_set_hl(0, "GitConflictAncestor", { bg = "#3a3a1a" })

  -- Markdown headings - vibrant colors with dark text
  vim.api.nvim_set_hl(0, "RenderMarkdownH1Bg", { bg = "#9ece6a", fg = "#16161e", bold = true })
  vim.api.nvim_set_hl(0, "RenderMarkdownH2Bg", { bg = "#7aa2f7", fg = "#16161e", bold = true })
  vim.api.nvim_set_hl(0, "RenderMarkdownH3Bg", { bg = "#f7768e", fg = "#16161e", bold = true })
  vim.api.nvim_set_hl(0, "RenderMarkdownH4Bg", { bg = "#ff9e64", fg = "#16161e", bold = true })
  vim.api.nvim_set_hl(0, "RenderMarkdownH5Bg", { bg = "#7dcfff", fg = "#16161e", bold = true })
  vim.api.nvim_set_hl(0, "RenderMarkdownH6Bg", { bg = "#bb9af7", fg = "#16161e", bold = true })

  -- Markdown checkboxes
  vim.api.nvim_set_hl(0, "RenderMarkdownTodoUnchecked", { fg = "#7aa2f7" })
  vim.api.nvim_set_hl(0, "RenderMarkdownTodoChecked", { fg = "#9ece6a", strikethrough = true })

  -- Additional diff highlights
  vim.api.nvim_set_hl(0, "DiffAdded", { fg = "#9ece6a", bg = "#1b3a2d" })
  vim.api.nvim_set_hl(0, "DiffRemoved", { fg = "#f7768e", bg = "#3a1a1a" })
  vim.api.nvim_set_hl(0, "DiffLine", { fg = "#7dcfff", bold = true })
  vim.api.nvim_set_hl(0, "DiffFile", { fg = "#bb9af7", bold = true })
end

return M
