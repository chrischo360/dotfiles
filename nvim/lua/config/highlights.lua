-- Shared highlight overrides for all themes
-- These are applied after the colorscheme loads

local M = {}

-- Light theme highlights (gruvbox light, solarized light, etc.)
M.light = function()
  -- Diff colors - soft pastels with dark text for light backgrounds
  vim.api.nvim_set_hl(0, "DiffAdd", { bg = "#d4f4dd", fg = "#1a5a1a" })
  vim.api.nvim_set_hl(0, "DiffDelete", { bg = "#ffdce0", fg = "#8b1a1a" })
  vim.api.nvim_set_hl(0, "DiffChange", { bg = "#fff8dc", fg = "#6b5a00" })
  vim.api.nvim_set_hl(0, "DiffText", { bg = "#ffe4a3", fg = "#1a1a1a", bold = true })

  -- Git signs in gutter
  vim.api.nvim_set_hl(0, "GitSignsAdd", { fg = "#22aa22" })
  vim.api.nvim_set_hl(0, "GitSignsDelete", { fg = "#dd2222" })
  vim.api.nvim_set_hl(0, "GitSignsChange", { fg = "#f57e20" })

  -- Markdown headings - soft pastel backgrounds with dark text
  vim.api.nvim_set_hl(0, "RenderMarkdownH1Bg", { bg = "#d4f5b8", fg = "#1a1a1a", bold = true })
  vim.api.nvim_set_hl(0, "RenderMarkdownH2Bg", { bg = "#d4e4fc", fg = "#1a1a1a", bold = true })
  vim.api.nvim_set_hl(0, "RenderMarkdownH3Bg", { bg = "#ffd4d4", fg = "#1a1a1a", bold = true })
  vim.api.nvim_set_hl(0, "RenderMarkdownH4Bg", { bg = "#ffe4cc", fg = "#1a1a1a", bold = true })
  vim.api.nvim_set_hl(0, "RenderMarkdownH5Bg", { bg = "#d4f4f4", fg = "#1a1a1a", bold = true })
  vim.api.nvim_set_hl(0, "RenderMarkdownH6Bg", { bg = "#e8d4fc", fg = "#1a1a1a", bold = true })

  -- Markdown checkboxes
  vim.api.nvim_set_hl(0, "RenderMarkdownTodoUnchecked", { fg = "#0ea5e9" })
  vim.api.nvim_set_hl(0, "RenderMarkdownTodoChecked", { fg = "#22c55e", strikethrough = true })

  -- Additional diff highlights
  vim.api.nvim_set_hl(0, "DiffAdded", { fg = "#1a5a1a", bg = "#d4f4dd" })
  vim.api.nvim_set_hl(0, "DiffRemoved", { fg = "#8b1a1a", bg = "#ffdce0" })
  vim.api.nvim_set_hl(0, "DiffLine", { fg = "#0369a1", bold = true })
  vim.api.nvim_set_hl(0, "DiffFile", { fg = "#7c3aed", bold = true })
end

-- Dark theme highlights (dracula, tokyonight, gruvbox dark, etc.)
M.dark = function()
  -- Diff colors - richer, more visible backgrounds with bright text
  vim.api.nvim_set_hl(0, "DiffAdd", { bg = "#2a4a3a", fg = "#a0e8b0" })
  vim.api.nvim_set_hl(0, "DiffDelete", { bg = "#4a2a2a", fg = "#ff9999" })
  vim.api.nvim_set_hl(0, "DiffChange", { bg = "#4a4a2a", fg = "#ffe680" })
  vim.api.nvim_set_hl(0, "DiffText", { bg = "#3a5a5a", fg = "#7dcfff", bold = true })

  -- Diffview.nvim specific
  vim.api.nvim_set_hl(0, "DiffviewDiffAdd", { bg = "#2a4a3a" })
  vim.api.nvim_set_hl(0, "DiffviewDiffDelete", { bg = "#4a2a2a" })
  vim.api.nvim_set_hl(0, "DiffviewDiffChange", { bg = "#4a4a2a" })
  vim.api.nvim_set_hl(0, "DiffviewDiffText", { bg = "#3a5a5a", fg = "#7dcfff", bold = true })

  -- Git signs in gutter
  vim.api.nvim_set_hl(0, "GitSignsAdd", { fg = "#9ece6a" })
  vim.api.nvim_set_hl(0, "GitSignsChange", { fg = "#ff9e64" })
  vim.api.nvim_set_hl(0, "GitSignsDelete", { fg = "#f7768e" })

  -- Git conflict highlights
  vim.api.nvim_set_hl(0, "GitConflictCurrent", { bg = "#2a4a3a" })
  vim.api.nvim_set_hl(0, "GitConflictIncoming", { bg = "#2d3a5a" })
  vim.api.nvim_set_hl(0, "GitConflictAncestor", { bg = "#4a4a2a" })

  -- Markdown headings - vibrant colors with slightly darker text
  vim.api.nvim_set_hl(0, "RenderMarkdownH1Bg", { bg = "#9ece6a", fg = "#0f0f14", bold = true })
  vim.api.nvim_set_hl(0, "RenderMarkdownH2Bg", { bg = "#7aa2f7", fg = "#0f0f14", bold = true })
  vim.api.nvim_set_hl(0, "RenderMarkdownH3Bg", { bg = "#f7768e", fg = "#0f0f14", bold = true })
  vim.api.nvim_set_hl(0, "RenderMarkdownH4Bg", { bg = "#ff9e64", fg = "#0f0f14", bold = true })
  vim.api.nvim_set_hl(0, "RenderMarkdownH5Bg", { bg = "#7dcfff", fg = "#0f0f14", bold = true })
  vim.api.nvim_set_hl(0, "RenderMarkdownH6Bg", { bg = "#bb9af7", fg = "#0f0f14", bold = true })

  -- Markdown checkboxes
  vim.api.nvim_set_hl(0, "RenderMarkdownTodoUnchecked", { fg = "#7aa2f7" })
  vim.api.nvim_set_hl(0, "RenderMarkdownTodoChecked", { fg = "#9ece6a", strikethrough = true })

  -- Additional diff highlights
  vim.api.nvim_set_hl(0, "DiffAdded", { fg = "#a0e8b0", bg = "#2a4a3a" })
  vim.api.nvim_set_hl(0, "DiffRemoved", { fg = "#ff9999", bg = "#4a2a2a" })
  vim.api.nvim_set_hl(0, "DiffLine", { fg = "#7dcfff", bold = true })
  vim.api.nvim_set_hl(0, "DiffFile", { fg = "#bb9af7", bold = true })
end

return M
