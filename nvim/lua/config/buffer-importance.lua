-- Buffer Importance Tracker Module
-- Tracks buffer usage metrics and calculates importance scores

local M = {}

-- Lazy load dependencies
local sqlite = nil
local Path = nil

-- Module state
M.initialized = false

-- Configuration defaults
M.config = {
  -- Weights for different metrics (should sum to 1.0)
  weights = {
    edit_frequency = 0.3,
    access_frequency = 0.25,
    time_spent = 0.25,
    relationships = 0.2,
  },
  -- Decay factor for recency (0-1, higher = faster decay)
  decay_factor = 0.95,
  -- Minimum events before considering a buffer "trackable"
  min_events = 3,
  -- Maximum number of buffers to track relationships for
  max_relationship_buffers = 50,
  -- Debounce time for metric updates (ms)
  debounce_ms = 1000,
  -- File patterns to exclude from tracking
  exclude_patterns = {
    "%.git/",
    "node_modules/",
    "%.lock$",
    "__pycache__/",
  },
}

-- Database setup
local db_path = vim.fn.stdpath("data") .. "/buffer_importance.db"
local db = nil

-- Initialize database schema
local function init_db()
  -- Lazy load dependencies with error handling
  if not sqlite then
    local ok, sql = pcall(require, "sqlite.db")
    if not ok then
      error("sqlite.lua is required but not installed. Please install 'kkharji/sqlite.lua'")
    end
    sqlite = sql
  end
  if not Path then
    local ok, p = pcall(require, "plenary.path")
    if not ok then
      error("plenary.nvim is required but not installed. Please install 'nvim-lua/plenary.nvim'")
    end
    Path = p
  end

  db = sqlite:open(db_path)

  -- Buffer metrics table
  db:execute([[
    CREATE TABLE IF NOT EXISTS buffer_metrics (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      filepath TEXT UNIQUE NOT NULL,
      edit_count INTEGER DEFAULT 0,
      save_count INTEGER DEFAULT 0,
      access_count INTEGER DEFAULT 0,
      total_time_ms INTEGER DEFAULT 0,
      last_access INTEGER DEFAULT 0,
      importance_score REAL DEFAULT 0.0,
      created_at INTEGER DEFAULT (strftime('%s', 'now')),
      updated_at INTEGER DEFAULT (strftime('%s', 'now'))
    )
  ]])

  -- Buffer relationships table (tracks co-occurrence)
  db:execute([[
    CREATE TABLE IF NOT EXISTS buffer_relationships (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      buffer1_path TEXT NOT NULL,
      buffer2_path TEXT NOT NULL,
      switch_count INTEGER DEFAULT 0,
      last_switch INTEGER DEFAULT 0,
      UNIQUE(buffer1_path, buffer2_path)
    )
  ]])

  -- Session tracking for time spent
  db:execute([[
    CREATE TABLE IF NOT EXISTS buffer_sessions (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      filepath TEXT NOT NULL,
      start_time INTEGER NOT NULL,
      end_time INTEGER,
      duration_ms INTEGER
    )
  ]])
end

-- Current session tracking
local current_session = {
  buffer = nil,
  start_time = nil,
}

-- Pending metric updates (for debouncing)
local pending_updates = {}
local update_timer = nil

-- Helper: Check if filepath should be excluded
local function should_exclude(filepath)
  for _, pattern in ipairs(M.config.exclude_patterns) do
    if filepath:match(pattern) then
      return true
    end
  end
  return false
end

-- Helper: Get or create buffer metrics
local function ensure_buffer_metrics(filepath)
  if should_exclude(filepath) then
    return nil
  end

  local existing = db:select("buffer_metrics", {
    where = { filepath = filepath }
  })

  if #existing == 0 then
    db:insert("buffer_metrics", {
      filepath = filepath,
      last_access = os.time()
    })
    return db:select("buffer_metrics", {
      where = { filepath = filepath }
    })[1]
  end

  return existing[1]
end

-- Apply time-based decay to scores
local function apply_decay()
  local current_time = os.time()
  local metrics = db:select("buffer_metrics")

  for _, metric in ipairs(metrics) do
    local days_since_access = (current_time - metric.last_access) / 86400
    local decay_multiplier = math.pow(M.config.decay_factor, days_since_access)

    db:update("buffer_metrics", {
      where = { id = metric.id },
      importance_score = metric.importance_score * decay_multiplier
    })
  end
end

-- Calculate importance score for a buffer
local function calculate_importance(metrics)
  local w = M.config.weights
  local score = 0

  -- Normalize metrics (simple scaling for now)
  local normalized = {
    edit = math.min(metrics.edit_count / 100, 1),
    access = math.min(metrics.access_count / 50, 1),
    time = math.min(metrics.total_time_ms / (1000 * 60 * 60), 1), -- 1 hour max
  }

  -- Calculate weighted score
  score = (
    normalized.edit * w.edit_frequency +
    normalized.access * w.access_frequency +
    normalized.time * w.time_spent
  )

  -- Add relationship bonus (calculated separately)
  -- Use raw SQL for complex WHERE clause with OR condition
  local relationships = db:eval([[
    SELECT * FROM buffer_relationships
    WHERE buffer1_path = ? OR buffer2_path = ?
  ]], { metrics.filepath, metrics.filepath })

  local relationship_score = 0
  for _, rel in ipairs(relationships) do
    relationship_score = relationship_score + (rel.switch_count * 0.01)
  end
  relationship_score = math.min(relationship_score, 1) * w.relationships

  return score + relationship_score
end

-- Debounced update function
local function perform_updates()
  for filepath, updates in pairs(pending_updates) do
    local metrics = ensure_buffer_metrics(filepath)
    if metrics then
      -- Apply updates
      local new_values = {
        edit_count = metrics.edit_count + (updates.edits or 0),
        save_count = metrics.save_count + (updates.saves or 0),
        access_count = metrics.access_count + (updates.accesses or 0),
        total_time_ms = metrics.total_time_ms + (updates.time or 0),
        last_access = os.time(),
        updated_at = os.time()
      }

      -- Update database
      db:update("buffer_metrics", vim.tbl_extend("force", {
        where = { id = metrics.id }
      }, new_values))

      -- Recalculate importance
      new_values.filepath = metrics.filepath
      local importance = calculate_importance(new_values)

      db:update("buffer_metrics", {
        where = { id = metrics.id },
        importance_score = importance
      })
    end
  end

  pending_updates = {}
  update_timer = nil
end

-- Queue a metric update
local function queue_update(filepath, update_type, value)
  if should_exclude(filepath) then
    return
  end

  if not pending_updates[filepath] then
    pending_updates[filepath] = {
      edits = 0,
      saves = 0,
      accesses = 0,
      time = 0
    }
  end

  pending_updates[filepath][update_type] = (pending_updates[filepath][update_type] or 0) + (value or 1)

  -- Debounce updates
  if update_timer then
    vim.fn.timer_stop(update_timer)
  end
  update_timer = vim.fn.timer_start(M.config.debounce_ms, perform_updates)
end

-- Track buffer enter event
function M.on_buf_enter()
  local filepath = vim.api.nvim_buf_get_name(0)
  if filepath == "" then return end

  -- End previous session
  if current_session.buffer and current_session.start_time then
    local duration = vim.fn.reltime(current_session.start_time)
    local duration_ms = math.floor(vim.fn.reltimefloat(duration) * 1000)

    queue_update(current_session.buffer, "time", duration_ms)

    -- Track relationship if switching between different buffers
    if current_session.buffer ~= filepath then
      M.track_relationship(current_session.buffer, filepath)
    end
  end

  -- Start new session
  current_session.buffer = filepath
  current_session.start_time = vim.fn.reltime()

  queue_update(filepath, "accesses")
end

-- Track buffer leave event
function M.on_buf_leave()
  if current_session.buffer and current_session.start_time then
    local duration = vim.fn.reltime(current_session.start_time)
    local duration_ms = math.floor(vim.fn.reltimefloat(duration) * 1000)

    queue_update(current_session.buffer, "time", duration_ms)
  end
end

-- Track text changes
function M.on_text_changed()
  local filepath = vim.api.nvim_buf_get_name(0)
  if filepath ~= "" then
    queue_update(filepath, "edits")
  end
end

-- Track buffer writes
function M.on_buf_write()
  local filepath = vim.api.nvim_buf_get_name(0)
  if filepath ~= "" then
    queue_update(filepath, "saves")
  end
end

-- Track relationship between buffers
function M.track_relationship(from_buffer, to_buffer)
  if from_buffer == to_buffer or should_exclude(from_buffer) or should_exclude(to_buffer) then
    return
  end

  -- Ensure consistent ordering
  local buffer1, buffer2 = from_buffer, to_buffer
  if from_buffer > to_buffer then
    buffer1, buffer2 = to_buffer, from_buffer
  end

  local existing = db:select("buffer_relationships", {
    where = { buffer1_path = buffer1, buffer2_path = buffer2 }
  })

  if #existing == 0 then
    db:insert("buffer_relationships", {
      buffer1_path = buffer1,
      buffer2_path = buffer2,
      switch_count = 1,
      last_switch = os.time()
    })
  else
    db:update("buffer_relationships", {
      where = { id = existing[1].id },
      switch_count = existing[1].switch_count + 1,
      last_switch = os.time()
    })
  end
end

-- Get sorted buffers by importance
function M.get_sorted_buffers()
  if not M.initialized or not db then
    return {}
  end

  apply_decay() -- Apply time decay before sorting

  local metrics = db:select("buffer_metrics", {
    order_by = "importance_score DESC",
    limit = 100
  })

  local results = {}
  for _, metric in ipairs(metrics) do
    -- Only include if file still exists
    if vim.fn.filereadable(metric.filepath) == 1 then
      table.insert(results, {
        filepath = metric.filepath,
        score = metric.importance_score,
        edits = metric.edit_count,
        saves = metric.save_count,
        accesses = metric.access_count,
        time_hours = metric.total_time_ms / (1000 * 60 * 60),
        last_access = metric.last_access
      })
    end
  end

  return results
end

-- Get importance indicator for a buffer
function M.get_importance_indicator(filepath)
  if not M.initialized or not db then
    return ""
  end

  local metrics = db:select("buffer_metrics", {
    where = { filepath = filepath }
  })

  if #metrics == 0 then
    return ""
  end

  local score = metrics[1].importance_score
  if score > 0.8 then
    return "🔥" -- Hot buffer
  elseif score > 0.5 then
    return "⭐" -- Important buffer
  elseif score > 0.3 then
    return "📌" -- Notable buffer
  else
    return ""
  end
end

-- Get related buffers for a given buffer
function M.get_related_buffers(filepath, limit)
  if not M.initialized or not db then
    return {}
  end

  limit = limit or 5

  -- Use raw SQL for complex WHERE clause with OR condition
  local relationships = db:eval([[
    SELECT * FROM buffer_relationships
    WHERE buffer1_path = ? OR buffer2_path = ?
    ORDER BY switch_count DESC
    LIMIT ?
  ]], { filepath, filepath, limit })

  local related = {}
  for _, rel in ipairs(relationships) do
    local related_path = rel.buffer1_path == filepath and rel.buffer2_path or rel.buffer1_path
    table.insert(related, {
      filepath = related_path,
      switches = rel.switch_count
    })
  end

  return related
end

-- Setup function
function M.setup(opts)
  if M.initialized then
    return -- Already initialized
  end

  M.config = vim.tbl_deep_extend("force", M.config, opts or {})

  -- Initialize database with error handling
  local ok, err = pcall(init_db)
  if not ok then
    vim.notify("Failed to initialize buffer importance: " .. tostring(err), vim.log.levels.ERROR)
    return
  end

  -- Set up autocmds
  local augroup = vim.api.nvim_create_augroup("BufferImportance", { clear = true })

  vim.api.nvim_create_autocmd("BufEnter", {
    group = augroup,
    callback = M.on_buf_enter
  })

  vim.api.nvim_create_autocmd("BufLeave", {
    group = augroup,
    callback = M.on_buf_leave
  })

  vim.api.nvim_create_autocmd({"TextChanged", "TextChangedI"}, {
    group = augroup,
    callback = vim.schedule_wrap(M.on_text_changed) -- Debounce text changes
  })

  vim.api.nvim_create_autocmd("BufWritePost", {
    group = augroup,
    callback = M.on_buf_write
  })

  -- Cleanup on exit
  vim.api.nvim_create_autocmd("VimLeavePre", {
    group = augroup,
    callback = function()
      M.on_buf_leave() -- End current session
      if update_timer then
        vim.fn.timer_stop(update_timer)
        perform_updates() -- Flush pending updates
      end
    end
  })

  -- Mark as initialized
  M.initialized = true
end

return M