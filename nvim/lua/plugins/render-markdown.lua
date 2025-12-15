-- Plugin: render-markdown.nvim
-- Description: Minimal markdown preview with checkbox strikethrough
-- Keybindings: <leader>mp (toggle markdown preview)
--
-- What this does:
--   - Headings: Shows icons (󰼏 through 󰼔) for H1-H6
--   - Checkboxes: Strikethrough for [x] checked items
--   - Code blocks: Syntax highlighting with language labels
--   - Links: Shows  icon for links
--   - Bullets: Shows ●○◆◇ for different nesting levels
--   - Bold/Italic: Renders **bold** and *italic* text with highlighting
--   - Quotes: Shows │ bar and background for block quotes

return {
  "MeanderingProgrammer/render-markdown.nvim",
  dependencies = {
    "nvim-treesitter/nvim-treesitter",
    "nvim-tree/nvim-web-devicons", -- Optional: for prettier icons
  },
  ft = { "markdown" }, -- Only load for markdown files
  config = function()
    require("render-markdown").setup({
      -- Enable/disable the plugin
      enabled = true,

      -- Headings: Just icons, simple
      heading = {
        enabled = true,
        icons = { "󰼏 ", "󰼐 ", "󰼑 ", "󰼒 ", "󰼓 ", "󰼔 " },
      },

      -- Code blocks: Syntax highlighting
      code = {
        enabled = true,
        style = "language", -- Shows language name
      },

      -- Checkboxes: THE KEY FEATURE - strikethrough for done items
      checkbox = {
        enabled = true,
        unchecked = {
          icon = "☐ ",
        },
        checked = {
          icon = "✓ ",
          scope_highlight = "@markup.strikethrough", -- THIS DOES THE STRIKETHROUGH
        },
      },

      -- Links: Show icon
      link = {
        enabled = true,
        icon = " ",
      },

      -- Bullet points: Simple
      bullet = {
        enabled = true,
        icons = { "●", "○", "◆", "◇" },
      },

      -- Bold/Italic: Render emphasis with highlighting
      emphasis = {
        enabled = true,
        -- **bold** text gets highlighted
        -- *italic* text gets highlighted
      },

      -- Block quotes: Show │ bar with background
      quote = {
        enabled = true,
        icon = "│ ",
      },
    })
  end,
  keys = {
    { "<leader>mp", "<cmd>RenderMarkdown toggle<cr>", desc = "Toggle Markdown Preview" },
  },
}
