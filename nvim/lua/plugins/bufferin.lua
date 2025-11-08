-- Plugin: Bufferin
-- Description: Buffer management interface for viewing and switching between open files/buffers.
-- Keybindings: <leader>b (toggle buffer list)

return {
  "wasabeef/bufferin.nvim",
  keys = {
    { "<leader>b", "<cmd>Bufferin<cr>", desc = "Toggle Bufferin" },
  },
  config = function()
    local bufferin = require("bufferin")
    local importance = require("config.buffer-importance-simple")
    local buffer_mod = require("bufferin.buffer")
    local utils = require("bufferin.utils")

    -- Setup bufferin with default config
    bufferin.setup()

    -- Cache for top 5 buffers (rebuilt when Bufferin opens)
    local top_5_cache = {}

    -- Override get_buffers to sort by importance AND rebuild top 5 cache
    local original_get_buffers = buffer_mod.get_buffers
    buffer_mod.get_buffers = function()
      local buffers = original_get_buffers()

      -- Get importance scores
      local scored_buffers = importance.get_all()
      local score_map = {}
      for _, scored in ipairs(scored_buffers) do
        score_map[scored.filepath] = scored.score
      end

      -- Rebuild top 5 cache for O(1) lookups in get_display_name
      top_5_cache = {}
      for i = 1, math.min(5, #scored_buffers) do
        top_5_cache[scored_buffers[i].filepath] = true
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

      return buffers
    end

    -- Override get_display_name to add pins for top 5 (using cache)
    local original_get_display_name = utils.get_display_name
    utils.get_display_name = function(name)
      local base_name = original_get_display_name(name)

      -- O(1) lookup instead of O(n) search
      if top_5_cache[name] then
        return "📌 " .. base_name
      end

      return base_name
    end
  end,
  --[[ OLD DISABLED CODE FOR REFERENCE
  config = function()
    local bufferin = require("bufferin")

    -- Safely load buffer importance with pcall
    local ok, importance = pcall(require, "config.buffer-importance")
    if not ok then
      vim.notify("Buffer importance module not loaded: " .. importance, vim.log.levels.WARN)
      -- Set up basic bufferin without importance features
      bufferin.setup()
      return
    end

    -- Initialize buffer importance tracker if not already initialized
    if not importance.initialized then
      importance.setup({
        -- You can override default config here if needed
        weights = {
          edit_frequency = 0.3,
          access_frequency = 0.25,
          time_spent = 0.25,
          relationships = 0.2,
        },
      })
    end

    -- Custom formatter to add importance indicators
    local function format_buffer_with_importance(buffer)
      local indicator = importance.get_importance_indicator(buffer.path)
      local name = buffer.name or vim.fn.fnamemodify(buffer.path, ":t")

      if indicator ~= "" then
        return indicator .. " " .. name
      end
      return name
    end

    -- Custom sorter that uses importance scores
    local function sort_by_importance(buffers)
      local scored_buffers = importance.get_sorted_buffers()
      local score_map = {}

      -- Create a map of filepath to score
      for _, scored in ipairs(scored_buffers) do
        score_map[scored.filepath] = scored.score
      end

      -- Sort buffers based on importance scores
      table.sort(buffers, function(a, b)
        local score_a = score_map[a.path] or 0
        local score_b = score_map[b.path] or 0

        -- If scores are equal, fall back to last used time
        if math.abs(score_a - score_b) < 0.01 then
          return (a.lastused or 0) > (b.lastused or 0)
        end

        return score_a > score_b
      end)

      return buffers
    end

    bufferin.setup({
      -- Override the default formatter
      formatter = format_buffer_with_importance,
      -- Custom filter to apply our sorting
      filter = function(buffers)
        -- First filter out special buffers (optional)
        local filtered = vim.tbl_filter(function(buf)
          return buf.name ~= "" and not buf.name:match("^%[")
        end, buffers)

        -- Then apply importance-based sorting
        return sort_by_importance(filtered)
      end,
      -- Show additional info in preview
      preview = {
        enabled = true,
        -- Custom preview content
        content = function(buffer)
          local lines = {}
          local metrics = importance.get_sorted_buffers()

          -- Find metrics for this buffer
          local buffer_metrics = nil
          for _, m in ipairs(metrics) do
            if m.filepath == buffer.path then
              buffer_metrics = m
              break
            end
          end

          if buffer_metrics then
            table.insert(lines, "📊 Buffer Statistics:")
            table.insert(lines, string.format("  Importance Score: %.2f", buffer_metrics.score))
            table.insert(lines, string.format("  Edit Count: %d", buffer_metrics.edits))
            table.insert(lines, string.format("  Save Count: %d", buffer_metrics.saves))
            table.insert(lines, string.format("  Access Count: %d", buffer_metrics.accesses))
            table.insert(lines, string.format("  Time Spent: %.1f hours", buffer_metrics.time_hours))
            table.insert(lines, "")

            -- Show related buffers
            local related = importance.get_related_buffers(buffer.path, 3)
            if #related > 0 then
              table.insert(lines, "🔗 Related Buffers:")
              for _, rel in ipairs(related) do
                local name = vim.fn.fnamemodify(rel.filepath, ":t")
                table.insert(lines, string.format("  %s (%d switches)", name, rel.switches))
              end
            end
          else
            table.insert(lines, "No importance data yet")
          end

          return lines
        end,
      },
    })
  end,
  --]] -- End of disabled block for step-by-step testing
  -- Optional dependencies for enhanced experience
  dependencies = {
    "nvim-tree/nvim-web-devicons", -- For file icons
    "willothy/nvim-cokeline", -- For buffer line integration
  },
}
