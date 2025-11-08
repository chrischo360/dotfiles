-- Telescope extension for buffer importance sorting
local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local entry_display = require("telescope.pickers.entry_display")
local utils = require("telescope.utils")

local M = {}

-- Custom buffer picker with importance sorting
function M.importance_buffers(opts)
  opts = opts or {}

  -- Safely load buffer importance module
  local ok, importance = pcall(require, "config.buffer-importance")
  if not ok then
    vim.notify("Buffer importance module not available", vim.log.levels.WARN)
    -- Fallback to regular buffer picker
    require("telescope.builtin").buffers(opts)
    return
  end

  -- Get all buffers
  local buffers = vim.tbl_filter(function(b)
    return vim.fn.buflisted(b) == 1
  end, vim.api.nvim_list_bufs())

  -- Get importance scores
  local scored_buffers = importance.get_sorted_buffers()
  local score_map = {}
  for _, scored in ipairs(scored_buffers) do
    score_map[scored.filepath] = scored
  end

  -- Create buffer entries with scores
  local buffer_entries = {}
  for _, bufnr in ipairs(buffers) do
    local filepath = vim.api.nvim_buf_get_name(bufnr)
    local score_data = score_map[filepath]

    table.insert(buffer_entries, {
      bufnr = bufnr,
      filepath = filepath,
      filename = vim.fn.fnamemodify(filepath, ":t"),
      score = score_data and score_data.score or 0,
      indicator = importance.get_importance_indicator(filepath),
      metrics = score_data
    })
  end

  -- Sort by importance score
  table.sort(buffer_entries, function(a, b)
    if math.abs(a.score - b.score) < 0.01 then
      -- Use bufnr as tiebreaker (newer buffers first)
      return a.bufnr > b.bufnr
    end
    return a.score > b.score
  end)

  -- Create entry maker
  local displayer = entry_display.create({
    separator = " ",
    items = {
      { width = 3 }, -- Indicator
      { width = 3 }, -- Buffer number
      { remaining = true }, -- Filename
      { width = 20 }, -- Relative path
    },
  })

  local make_display = function(entry)
    local filepath = entry.filepath
    local dir_name = vim.fn.fnamemodify(filepath, ":h:t")
    if dir_name == "." then
      dir_name = ""
    else
      dir_name = dir_name .. "/"
    end

    return displayer({
      { entry.indicator, "TelescopeResultsNumber" },
      { tostring(entry.bufnr), "TelescopeResultsNumber" },
      entry.filename,
      { dir_name, "TelescopeResultsComment" },
    })
  end

  local entry_maker = function(entry)
    return {
      value = entry.bufnr,
      ordinal = entry.filename .. " " .. entry.filepath,
      display = make_display,

      bufnr = entry.bufnr,
      filename = entry.filepath,
      filepath = entry.filepath,
      indicator = entry.indicator,
      metrics = entry.metrics,
    }
  end

  pickers.new(opts, {
    prompt_title = "Buffers (Sorted by Importance)",
    finder = finders.new_table({
      results = buffer_entries,
      entry_maker = entry_maker,
    }),
    sorter = conf.generic_sorter(opts),
    attach_mappings = function(prompt_bufnr, map)
      local delete_buffer = function()
        local current_picker = action_state.get_current_picker(prompt_bufnr)
        local selection = action_state.get_selected_entry()

        if selection then
          vim.api.nvim_buf_delete(selection.bufnr, { force = false })
          current_picker:refresh(finders.new_table({
            results = vim.tbl_filter(function(b)
              return b.bufnr ~= selection.bufnr
            end, buffer_entries),
            entry_maker = entry_maker,
          }), { reset_prompt = false })
        end
      end

      local show_info = function()
        local selection = action_state.get_selected_entry()
        if selection and selection.metrics then
          local m = selection.metrics
          vim.notify(string.format(
            "📊 Buffer: %s\nScore: %.2f | Edits: %d | Saves: %d | Time: %.1fh",
            vim.fn.fnamemodify(m.filepath, ":t"),
            m.score,
            m.edits,
            m.saves,
            m.time_hours
          ), vim.log.levels.INFO)
        else
          vim.notify("No importance data for this buffer yet", vim.log.levels.INFO)
        end
      end

      -- Set up mappings
      map("i", "<c-d>", delete_buffer)
      map("n", "dd", delete_buffer)
      map("i", "<c-i>", show_info)
      map("n", "i", show_info)

      return true
    end,
    previewer = conf.file_previewer(opts),
  }):find()
end

return M