-- Plugin: External Image Viewer
-- Description: Open images in macOS default viewer (Preview)
-- Keybindings:
--   <leader>io - Open image under cursor/path externally
--   <leader>ic - Copy image path to clipboard
--
-- NOTE: This is configured for external viewing due to Alacritty limitations on macOS.
-- To enable inline image support:
--   1. Switch to Kitty terminal (https://sw.kovidgoyal.net/kitty/)
--   2. Uncomment the image.nvim config below
--   3. Comment out the external viewer keybindings

-- =============================================================================
-- EXTERNAL VIEWER (Current Setup - Works with Alacritty)
-- =============================================================================

-- Helper function to get image path under cursor
local function get_image_path()
  -- Try to get path from markdown image syntax: ![alt](path)
  local line = vim.api.nvim_get_current_line()
  local col = vim.api.nvim_win_get_cursor(0)[2]

  -- Match markdown image: ![...](...) or plain path
  local img_path = line:match("%[.-%]%((.-)%)") or line:match("([%w%.%/%-_]+%.%w+)")

  if not img_path then
    -- Try <cfile> (file under cursor)
    img_path = vim.fn.expand("<cfile>")
  end

  if not img_path or img_path == "" then
    return nil
  end

  -- Expand ~ and environment variables first
  if img_path:match("^~") or img_path:match("%$") then
    img_path = vim.fn.expand(img_path)
  end

  -- Expand to absolute path only if truly relative (not absolute, not URL)
  if not img_path:match("^/") and not img_path:match("^https?://") then
    local current_file_dir = vim.fn.expand("%:p:h")
    img_path = current_file_dir .. "/" .. img_path
  end

  return img_path
end

-- Open image in default macOS viewer
local function open_image_external()
  local img_path = get_image_path()

  if not img_path or img_path == "" then
    vim.notify("No image path found under cursor", vim.log.levels.WARN)
    return
  end

  -- Check if file exists
  if vim.fn.filereadable(img_path) == 0 and not img_path:match("^https?://") then
    vim.notify("Image file not found: " .. img_path, vim.log.levels.ERROR)
    return
  end

  -- Open with macOS 'open' command
  vim.fn.jobstart({ "open", img_path }, { detach = true })
  vim.notify("Opening: " .. img_path, vim.log.levels.INFO)
end

-- Copy image path to clipboard
local function copy_image_path()
  local img_path = get_image_path()

  if not img_path or img_path == "" then
    vim.notify("No image path found under cursor", vim.log.levels.WARN)
    return
  end

  vim.fn.setreg("+", img_path)
  vim.notify("Copied to clipboard: " .. img_path, vim.log.levels.INFO)
end

-- Keybindings for external viewer
vim.keymap.set("n", "<leader>io", open_image_external, { desc = "Open image externally" })
vim.keymap.set("n", "<leader>ic", copy_image_path, { desc = "Copy image path" })

-- =============================================================================
-- INLINE IMAGE SUPPORT (Requires Kitty Terminal)
-- =============================================================================
-- Uncomment this section if you switch to Kitty terminal for inline image support
--[[
return {
  "3rd/image.nvim",
  dependencies = {
    "leafo/magick", -- ImageMagick Lua bindings (brew install imagemagick already done)
  },
  ft = { "markdown", "norg", "md" }, -- Lazy load on these filetypes
  opts = {
    backend = "kitty", -- Use kitty graphics protocol
    integrations = {
      markdown = {
        enabled = true,
        clear_in_insert_mode = true, -- Better performance
        download_remote_images = true,
        only_render_image_at_cursor = false,
        filetypes = { "markdown", "vimwiki", "md" },
      },
      neorg = {
        enabled = true,
        clear_in_insert_mode = true,
        download_remote_images = true,
        only_render_image_at_cursor = false,
        filetypes = { "norg" },
      },
    },
    -- Performance settings
    max_width = 100,
    max_height = 12,
    max_width_window_percentage = nil,
    max_height_window_percentage = 50,
    -- Window settings
    window_overlap_clear_enabled = true,
    window_overlap_clear_ft_ignore = { "cmp_menu", "cmp_docs", "" },
    -- Editor behavior
    editor_only_render_when_focused = true,
    tmux_show_only_in_active_window = true,
    -- Hijack file patterns to preview
    hijack_file_patterns = {
      "*.png",
      "*.jpg",
      "*.jpeg",
      "*.gif",
      "*.webp",
      "*.svg",
    },
  },
  keys = {
    { "<leader>it", "<cmd>lua require('image').toggle()<cr>", desc = "Toggle image rendering" },
  },
}
--]]

-- Return empty table since we're using keybindings only
return {}
