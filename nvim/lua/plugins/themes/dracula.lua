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
    require("config.highlights").dark()  -- Apply shared dark theme highlights
  end,
}
