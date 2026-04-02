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
    -- Disable line wrapping for markdown files to prevent long links from wrapping
    vim.api.nvim_create_autocmd("FileType", {
      pattern = "markdown",
      callback = function()
        vim.opt_local.wrap = true

        -- Color link text based on destination URL
        local ns = vim.api.nvim_create_namespace("markdown_link_text_colors")

        local function highlight_link_text()
          local bufnr = vim.api.nvim_get_current_buf()
          vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)

          local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
          for lnum, line in ipairs(lines) do
            -- Match [text](url) pattern
            local pos = 1
            while pos <= #line do
              local text_start, text_end, text_content, url = line:find("%[([^%]]+)%]%(([^%)]+)%)", pos)
              if not text_start then break end

              local hl_group = nil
              if url:match("github%.com") then
                hl_group = "MarkdownLinkTextGitHub"
              elseif url:match("projecthub%.service%.csnzoo%.com") then
                hl_group = "MarkdownLinkTextProjectHub"
              elseif url:match("buildkite%.com") then
                hl_group = "MarkdownLinkTextBuildkite"
              elseif url:match("^[%.~/]") then
                hl_group = "MarkdownLinkTextLocal"
              elseif url:match("^https?://") then
                hl_group = "MarkdownLinkTextExternal"
              end

              if hl_group then
                -- Highlight only the text portion (inside the brackets)
                vim.api.nvim_buf_add_highlight(bufnr, ns, hl_group, lnum - 1, text_start, text_start + #text_content)
              end

              pos = text_end + 1
            end
          end
        end

        -- Apply highlighting on buffer load and changes
        highlight_link_text()
        vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI", "BufEnter" }, {
          buffer = 0,
          callback = highlight_link_text,
        })
      end,
    })
    -- Custom link highlight groups (adapt to light/dark mode)
    local function set_link_colors()
      if vim.o.background == "light" then
        -- Light mode: softer, less saturated colors
        vim.api.nvim_set_hl(0, "RenderMarkdownLinkGitHub", { fg = "#a855f7", bold = true })      -- Softer purple
        vim.api.nvim_set_hl(0, "RenderMarkdownLinkProjectHub", { fg = "#0891b2", bold = true })  -- Softer cyan
        vim.api.nvim_set_hl(0, "RenderMarkdownLinkBuildkite", { fg = "#ea580c", bold = true })   -- Softer orange
        vim.api.nvim_set_hl(0, "RenderMarkdownLinkLocal", { fg = "#16a34a", bold = true })       -- Softer green
        vim.api.nvim_set_hl(0, "RenderMarkdownLinkExternal", { fg = "#2563eb", bold = true })    -- Softer blue

        -- Link text highlighting (no bold)
        vim.api.nvim_set_hl(0, "MarkdownLinkTextGitHub", { fg = "#a855f7" })
        vim.api.nvim_set_hl(0, "MarkdownLinkTextProjectHub", { fg = "#0891b2" })
        vim.api.nvim_set_hl(0, "MarkdownLinkTextBuildkite", { fg = "#ea580c" })
        vim.api.nvim_set_hl(0, "MarkdownLinkTextLocal", { fg = "#16a34a" })
        vim.api.nvim_set_hl(0, "MarkdownLinkTextExternal", { fg = "#2563eb" })
        vim.api.nvim_set_hl(0, "RenderMarkdownTodoChecked", { fg = "#d20f39", strikethrough = true })
      else
        -- Dark mode: bright, vibrant colors
        vim.api.nvim_set_hl(0, "RenderMarkdownLinkGitHub", { fg = "#ff79c6", bold = true })      -- Bright pink
        vim.api.nvim_set_hl(0, "RenderMarkdownLinkProjectHub", { fg = "#89dceb", bold = true })  -- Bright cyan
        vim.api.nvim_set_hl(0, "RenderMarkdownLinkBuildkite", { fg = "#ff9e64", bold = true })   -- Orange
        vim.api.nvim_set_hl(0, "RenderMarkdownLinkLocal", { fg = "#9ece6a", bold = true })       -- Green
        vim.api.nvim_set_hl(0, "RenderMarkdownLinkExternal", { fg = "#7aa2f7", bold = true })    -- Light blue

        -- Link text highlighting (no bold)
        vim.api.nvim_set_hl(0, "MarkdownLinkTextGitHub", { fg = "#ff79c6" })
        vim.api.nvim_set_hl(0, "MarkdownLinkTextProjectHub", { fg = "#89dceb" })
        vim.api.nvim_set_hl(0, "MarkdownLinkTextBuildkite", { fg = "#ff9e64" })
        vim.api.nvim_set_hl(0, "MarkdownLinkTextLocal", { fg = "#9ece6a" })
        vim.api.nvim_set_hl(0, "MarkdownLinkTextExternal", { fg = "#7aa2f7" })
        vim.api.nvim_set_hl(0, "RenderMarkdownTodoChecked", { fg = "#9ece6a", strikethrough = true })
      end
    end

    -- Set colors initially
    set_link_colors()

    -- Update colors when background changes
    vim.api.nvim_create_autocmd("OptionSet", {
      pattern = "background",
      callback = set_link_colors,
    })

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
          -- No scope_highlight: lets links show their proper colors
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
            icon = "󰃀 ",
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
            icon = "󰈔 ",
            highlight = "RenderMarkdownLinkLocal",
            priority = 10, -- Higher priority than generic http pattern
          },
          -- External web links (light blue, lowest priority)
          web = {
            pattern = "^http",
            icon = "󰖟 ",
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
