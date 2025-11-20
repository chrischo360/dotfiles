-- Step 1: Simple buffer tracking test
-- This file loads automatically after all plugins
-- We'll test this first before adding UI integration

local tracker = require("config.buffer-importance-simple")

-- Initialize the simple tracker
tracker.setup()

-- Add test command
vim.api.nvim_create_user_command("BufferTrackingTest", function()
  local all = tracker.get_all()

  if #all == 0 then
    vim.notify("No buffers tracked yet. Open some files and save them!", vim.log.levels.INFO)
    return
  end

  local lines = { "📊 Tracked Buffers (by importance score):", "" }
  for i, buf in ipairs(all) do
    if i > 10 then break end -- Only show top 10
    local name = vim.fn.fnamemodify(buf.filepath, ":t")
    local indicator = ""
    if buf.score > 0.7 then
      indicator = "🔥"
    elseif buf.score > 0.4 then
      indicator = "⭐"
    elseif buf.score > 0.2 then
      indicator = "📌"
    end

    table.insert(lines, string.format(
      "%d. %s %s (score: %.2f) - %d accesses, %d saves",
      i,
      indicator,
      name,
      buf.score,
      buf.access,
      buf.saves
    ))
  end

  vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO)
end, {
  desc = "Show buffer tracking test results"
})

vim.api.nvim_create_user_command("BufferTrackingStats", function()
  local filepath = vim.api.nvim_buf_get_name(0)
  local stats = tracker.get_stats(filepath)

  if stats then
    local indicator = ""
    if stats.score > 0.7 then
      indicator = "🔥 Hot"
    elseif stats.score > 0.4 then
      indicator = "⭐ Important"
    elseif stats.score > 0.2 then
      indicator = "📌 Notable"
    else
      indicator = "📄 Normal"
    end

    vim.notify(string.format(
      "%s Buffer: %s\n\n" ..
      "Importance Score: %.2f\n" ..
      "Access Count: %d\n" ..
      "Save Count: %d",
      indicator,
      vim.fn.fnamemodify(filepath, ":t"),
      stats.score,
      stats.access,
      stats.saves
    ), vim.log.levels.INFO)
  else
    vim.notify("No tracking data for current buffer yet", vim.log.levels.INFO)
  end
end, {
  desc = "Show current buffer tracking stats"
})