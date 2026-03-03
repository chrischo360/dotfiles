-- Plugin: Bufferin
-- Description: Buffer management interface for viewing and switching between open files/buffers.
-- Keybindings: <leader>b (toggle buffer list)

return {
  "wasabeef/bufferin.nvim",
  enabled = false,
  keys = {
    { "<leader>b", "<cmd>Bufferin<cr>", desc = "Toggle Bufferin" },
  },
  config = function()
    local bufferin = require("bufferin")
    local importance = require("config.buffer-importance-simple")
    local buffer_mod = require("bufferin.buffer")
    local utils = require("bufferin.utils")

    -- Initialize buffer importance tracking
    if not importance.initialized then
      importance.setup()
    end

    -- Setup bufferin with custom display config
    bufferin.setup({
      display = {
        show_numbers = false,  -- Remove buffer number prefix (20:, 22:, etc.)
        show_path = false,     -- Remove directory path suffix
        show_icons = true,     -- Keep file type icons
        show_modified = true,  -- Keep modified indicator (●)
      }
    })

    -- Cache for top 5 buffers and from_main markers (rebuilt when Bufferin opens)
    local top_5_cache = {}
    local from_main_cache = {}

    -- Override get_buffers to sort by importance AND rebuild caches
    local original_get_buffers = buffer_mod.get_buffers
    buffer_mod.get_buffers = function()
      local buffers = original_get_buffers()

      -- Get importance scores (includes merged main files on feature branches)
      local scored_buffers = importance.get_all()
      local score_map = {}
      for _, scored in ipairs(scored_buffers) do
        score_map[scored.filepath] = scored.score
      end

      -- Rebuild top 5 cache and from_main cache for O(1) lookups in get_display_name
      top_5_cache = {}
      from_main_cache = {}
      for i = 1, math.min(5, #scored_buffers) do
        top_5_cache[scored_buffers[i].filepath] = true
      end
      for _, scored in ipairs(scored_buffers) do
        if scored.from_main then
          from_main_cache[scored.filepath] = true
        end
      end

      -- Sort by importance
      table.sort(buffers, function(a, b)
        local score_a = score_map[a.name] or 0
        local score_b = score_map[b.name] or 0

        if math.abs(score_a - score_b) < 0.01 then
          return (a.current and not b.current) or false
        end

        return score_a > score_b
      end)

      -- Limit to top 15 most important buffers
      local filtered_buffers = {}
      for i = 1, math.min(15, #buffers) do
        table.insert(filtered_buffers, buffers[i])
      end

      return filtered_buffers
    end

    -- Override get_display_name to add pins for top 5 and markers for main files
    local original_get_display_name = utils.get_display_name
    utils.get_display_name = function(name)
      -- Extract parent directory + filename (e.g., plugins/bufferin.lua)
      local parent_dir = vim.fn.fnamemodify(name, ":h:t")
      local filename = vim.fn.fnamemodify(name, ":t")

      -- Handle edge case: files in root or no parent directory
      local base_name
      if parent_dir == "" or parent_dir == "." then
        base_name = filename
      else
        base_name = parent_dir .. "/" .. filename
      end

      -- O(1) lookups
      local is_top_5 = top_5_cache[name]
      local from_main = from_main_cache[name]

      -- Build display: filename, icon (if pinned), then pin status
      local display = base_name

      -- Add file type icon after filename for pinned buffers
      if is_top_5 or from_main then
        local icons_module = require("bufferin.icons")
        local icon, icon_hl = icons_module.get_icon(name)
        if icon and icon ~= '' then
          display = display .. " " .. icon
        end
      end

      -- Add pin indicator at the end
      if is_top_5 and from_main then
        return display .. " 📌 (main)"
      elseif is_top_5 then
        return display .. " 📌"
      elseif from_main then
        return display .. " (main)"
      else
        return display
      end
    end
  end,
  -- Optional dependencies for enhanced experience
  dependencies = {
    "nvim-tree/nvim-web-devicons", -- For file icons
    "willothy/nvim-cokeline", -- For buffer line integration
  },
}
