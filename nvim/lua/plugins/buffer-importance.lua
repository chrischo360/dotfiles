-- Plugin configuration for buffer importance
-- DISABLED FOR STEP-BY-STEP TESTING
-- This sets up user commands and keybindings for managing buffer importance

return {} -- Temporarily disabled
--[[ DISABLED
return {
  -- Standalone plugin configuration for buffer importance commands
  {
    name = "buffer-importance-commands",
    lazy = false,
    dependencies = {
      "kkharji/sqlite.lua",
      "nvim-lua/plenary.nvim",
    },
    config = function()
      -- Set up buffer importance commands
      local importance = require("config.buffer-importance")

      -- User commands
      vim.api.nvim_create_user_command("BufferStats", function()
        local filepath = vim.api.nvim_buf_get_name(0)
        local metrics = importance.get_sorted_buffers()

        for _, m in ipairs(metrics) do
          if m.filepath == filepath then
            vim.notify(string.format(
              "📊 Current Buffer Statistics:\n" ..
              "Score: %.2f\n" ..
              "Edit Count: %d\n" ..
              "Save Count: %d\n" ..
              "Access Count: %d\n" ..
              "Time Spent: %.1f hours\n" ..
              "Last Access: %s",
              m.score,
              m.edits,
              m.saves,
              m.accesses,
              m.time_hours,
              os.date("%Y-%m-%d %H:%M", m.last_access)
            ), vim.log.levels.INFO)
            return
          end
        end

        vim.notify("No importance data for this buffer yet", vim.log.levels.INFO)
      end, {
        desc = "Show importance statistics for current buffer"
      })

      vim.api.nvim_create_user_command("BufferImportanceTop", function(args)
        local limit = tonumber(args.args) or 10
        local metrics = importance.get_sorted_buffers()

        if #metrics == 0 then
          vim.notify("No buffer importance data yet", vim.log.levels.INFO)
          return
        end

        local lines = { "🔝 Top " .. limit .. " Most Important Buffers:" }
        for i = 1, math.min(limit, #metrics) do
          local m = metrics[i]
          local indicator = importance.get_importance_indicator(m.filepath)
          local name = vim.fn.fnamemodify(m.filepath, ":~:.")
          table.insert(lines, string.format(
            "%d. %s %s (%.2f) - %d edits, %.1fh",
            i,
            indicator,
            name,
            m.score,
            m.edits,
            m.time_hours
          ))
        end

        vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO)
      end, {
        nargs = "?",
        desc = "Show top N most important buffers (default 10)"
      })

      vim.api.nvim_create_user_command("BufferImportanceRelated", function()
        local filepath = vim.api.nvim_buf_get_name(0)
        local related = importance.get_related_buffers(filepath, 10)

        if #related == 0 then
          vim.notify("No related buffers found", vim.log.levels.INFO)
          return
        end

        local lines = { "🔗 Buffers Related to Current:" }
        for i, rel in ipairs(related) do
          local name = vim.fn.fnamemodify(rel.filepath, ":~:.")
          table.insert(lines, string.format(
            "%d. %s (%d switches)",
            i,
            name,
            rel.switches
          ))
        end

        vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO)
      end, {
        desc = "Show buffers frequently used with current buffer"
      })

      vim.api.nvim_create_user_command("BufferImportanceReset", function(args)
        if args.bang then
          -- Reset all data
          local db_path = vim.fn.stdpath("data") .. "/buffer_importance.db"
          vim.fn.delete(db_path)
          vim.notify("Buffer importance data reset. Restart Neovim to reinitialize.", vim.log.levels.WARN)
        else
          vim.notify("Use :BufferImportanceReset! to confirm resetting all data", vim.log.levels.WARN)
        end
      end, {
        bang = true,
        desc = "Reset all buffer importance data (use ! to confirm)"
      })

      -- Optional: Add status line component
      vim.g.buffer_importance_statusline = function()
        local filepath = vim.api.nvim_buf_get_name(0)
        local indicator = importance.get_importance_indicator(filepath)
        if indicator ~= "" then
          return indicator .. " "
        end
        return ""
      end
    end
  }
}
--]]
-- End of disabled block

