-- Plugin: render-markdown.nvim
-- Description: Minimal markdown preview with checkbox strikethrough
-- Keybindings: <leader>mp (toggle markdown preview)
--
-- What this does:
--   - Headings: Shows icons (󰼏 through 󰼔) for H1-H6
--   - Checkboxes: Green for [ ] unchecked, red strikethrough for [x] checked
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
    -- Custom link highlight groups
    vim.api.nvim_set_hl(0, "RenderMarkdownLinkGitHub", { fg = "#a371f7", bold = true })      -- Purple
    vim.api.nvim_set_hl(0, "RenderMarkdownLinkProjectHub", { fg = "#58a6ff", bold = true })  -- Blue
    vim.api.nvim_set_hl(0, "RenderMarkdownLinkBuildkite", { fg = "#ff9e64", bold = true })   -- Orange
    vim.api.nvim_set_hl(0, "RenderMarkdownLinkLocal", { fg = "#9ece6a", bold = true })       -- Green
    vim.api.nvim_set_hl(0, "RenderMarkdownLinkExternal", { fg = "#7aa2f7", bold = true })    -- Light blue

    require("render-markdown").setup({
      -- Enable/disable the plugin
      enabled = true,

      -- Headings: Icons with controlled backgrounds
      heading = {
        enabled = true,
        icons = { "󰼏 ", "󰼐 ", "󰼑 ", "󰼒 ", "󰼓 ", "󰼔 " },

        -- Background configuration
        -- Set to {} to disable all backgrounds
        -- Or list specific levels: { 'RenderMarkdownH1Bg', 'RenderMarkdownH2Bg' }
        backgrounds = {
          'RenderMarkdownH1Bg',
          'RenderMarkdownH2Bg',
          'RenderMarkdownH3Bg',
          'RenderMarkdownH4Bg',
          'RenderMarkdownH5Bg',
          'RenderMarkdownH6Bg',
        },

        -- Width: 'full' = entire window, 'block' = only heading text width
        width = 'full',

        -- Padding (only applies when width = 'block')
        left_pad = 0,
        right_pad = 0,
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
          scope_highlight = "RenderMarkdownTodoUnchecked",
        },
        checked = {
          icon = "✓ ",
          scope_highlight = "RenderMarkdownTodoChecked",
        },
      },

      -- Links: Custom icons and colors per link type
      link = {
        enabled = true,
        hyperlink = "󰌷 ", -- Default fallback icon
        custom = {
          -- GitHub links (purple)
          github = {
            pattern = "github%.com",
            icon = "󰊤 ",
            highlight = "RenderMarkdownLinkGitHub",
          },
          -- ProjectHub links (blue)
          projecthub = {
            pattern = "projecthub%.service%.csnzoo%.com",
            icon = "󱗖 ",
            highlight = "RenderMarkdownLinkProjectHub",
          },
          -- Buildkite links (orange)
          buildkite = {
            pattern = "buildkite%.com",
            icon = "󰱑 ",
            highlight = "RenderMarkdownLinkBuildkite",
          },
          -- Relative/local file paths (green)
          -- Matches: ./file, ../file, ~/file
          relative = {
            pattern = "^[%.~]",
            icon = "📄 ",
            highlight = "RenderMarkdownLinkLocal",
            priority = 10, -- Higher priority than generic http pattern
          },
          -- External web links (light blue, lowest priority)
          web = {
            pattern = "^http",
            icon = "🌐 ",
            highlight = "RenderMarkdownLinkExternal",
            priority = 1, -- Lowest priority (checked last)
          },
        },
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
