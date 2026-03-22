-- Theme: Dracula
-- Description: Popular purple/pink dark theme with high contrast and vibrant colors.
-- Variants: dracula, dracula-soft

return {
  "Mofiqul/dracula.nvim",
  enabled = false,
  priority = 1000,
  opts = {
    transparent_bg = false,
    italic_comment = true,
    -- Override diff colors for better visibility
    overrides = function(colors)
      return {
        CursorLine = { bg = "#1e3a2a" },                 -- Current line: dark green tint
        CursorLineNr = { fg = "#50fa7b", bold = true }, -- Current line number: Dracula green

        -- Standard Vim diff highlights (used by :diffsplit, gitsigns inline diff)
        DiffAdd = { bg = "#2d4a3e", fg = "NONE" },      -- Added lines: green tint background
        DiffChange = { bg = "#3d3d1e", fg = "NONE" },  -- Changed lines: yellow tint background
        DiffDelete = { bg = "#4a2d2d", fg = "#ff5555" }, -- Deleted lines: red tint + red text
        DiffText = { bg = "#5c5c00", fg = "#f1fa8c", bold = true }, -- Changed text: bright yellow highlight

        -- Diffview.nvim specific highlights
        DiffviewDiffAdd = { bg = "#2d4a3e" },          -- Added lines in diffview
        DiffviewDiffDelete = { bg = "#4a2d2d" },      -- Deleted lines in diffview
        DiffviewDiffChange = { bg = "#3d3d1e" },      -- Changed lines in diffview
        DiffviewDiffText = { bg = "#5c5c00", fg = "#f1fa8c", bold = true }, -- Changed text

        -- Git signs in gutter (left margin indicators)
        GitSignsAdd = { fg = "#50fa7b" },              -- Bright green for additions
        GitSignsChange = { fg = "#ffb86c" },          -- Orange for changes
        GitSignsDelete = { fg = "#ff5555" },          -- Red for deletions

        -- Git conflict highlights (git-conflict.nvim)
        GitConflictCurrent = { bg = "#2d4a3e" },      -- Current/ours (green tint)
        GitConflictIncoming = { bg = "#3d3d5c" },     -- Incoming/theirs (purple tint)
        GitConflictAncestor = { bg = "#3d3d1e" },     -- Base/ancestor (yellow tint)
      }
    end,
  },
  config = function(_, opts)
    require("dracula").setup(opts)

    -- Set variant: "dracula" (default) or "dracula-soft"
    vim.cmd.colorscheme("dracula")  -- Change to "dracula-soft" for softer colors

    -- Custom markdown heading colors for render-markdown.nvim
    vim.api.nvim_set_hl(0, "RenderMarkdownH1Bg", { bg = "#a3e635", fg = "#1a1a1a", bold = true })  -- Green
    vim.api.nvim_set_hl(0, "RenderMarkdownH2Bg", { bg = "#60a5fa", fg = "#1a1a1a", bold = true })  -- Blue
    vim.api.nvim_set_hl(0, "RenderMarkdownH3Bg", { bg = "#f87171", fg = "#1a1a1a", bold = true })  -- Red
    vim.api.nvim_set_hl(0, "RenderMarkdownH4Bg", { bg = "#fb923c", fg = "#1a1a1a", bold = true })  -- Orange
    vim.api.nvim_set_hl(0, "RenderMarkdownH5Bg", { bg = "#2dd4bf", fg = "#1a1a1a", bold = true })  -- Teal
    vim.api.nvim_set_hl(0, "RenderMarkdownH6Bg", { bg = "#c084fc", fg = "#1a1a1a", bold = true })  -- Purple

    -- Markdown checkbox state colors
    vim.api.nvim_set_hl(0, "RenderMarkdownTodoUnchecked", { fg = "#8be9fd" })
    vim.api.nvim_set_hl(0, "RenderMarkdownTodoChecked",   { fg = "#50fa7b", strikethrough = true })

    -- Additional diff highlights that may not be in overrides
    -- These ensure consistent colors across all diff views
    vim.api.nvim_set_hl(0, "DiffAdded", { fg = "#50fa7b", bg = "#2d4a3e" })
    vim.api.nvim_set_hl(0, "DiffRemoved", { fg = "#ff5555", bg = "#4a2d2d" })
    vim.api.nvim_set_hl(0, "DiffLine", { fg = "#8be9fd", bold = true })       -- @@ line numbers
    vim.api.nvim_set_hl(0, "DiffFile", { fg = "#bd93f9", bold = true })       -- File headers
  end,
}
