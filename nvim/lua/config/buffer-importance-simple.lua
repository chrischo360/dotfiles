-- Simple Buffer Importance Tracker - JSON-based (no SQLite)
-- Tracks buffer access and saves

local M = {}

-- State
M.initialized = false
local buffer_data = {} -- { [filepath] = { access = 0, saves = 0 } }
local save_timer = nil -- Timer for debounced saves
local data_file = nil -- Will be set based on project root
local current_project_root = nil -- Track which project we're in

-- Detect project root (git root, LSP root, or cwd)
local function detect_project_root()
  -- Try git root first
  local git_root = vim.fn.systemlist("git -C " .. vim.fn.shellescape(vim.fn.getcwd()) .. " rev-parse --show-toplevel")[1]
  if vim.v.shell_error == 0 and git_root and git_root ~= "" then
    return git_root
  end

  -- Try LSP root
  local bufnr = vim.api.nvim_get_current_buf()
  local clients = vim.lsp.get_active_clients({ bufnr = bufnr })
  for _, client in ipairs(clients) do
    if client.config.root_dir then
      return client.config.root_dir
    end
  end

  -- Fallback to current working directory
  return vim.fn.getcwd()
end

-- Simple hash function to create unique filename from path
local function hash_path(path)
  local hash = 0
  for i = 1, #path do
    hash = (hash * 31 + string.byte(path, i)) % 1000000
  end
  return string.format("project-%06d", hash)
end

-- Get data file path for current project
local function get_data_file()
  local project_root = detect_project_root()

  -- If project changed, set up new data file
  if project_root ~= current_project_root then
    current_project_root = project_root

    -- Create tracking directory if it doesn't exist
    local tracking_dir = vim.fn.stdpath("data") .. "/buffer_tracking"
    vim.fn.mkdir(tracking_dir, "p")

    -- Generate project-specific filename
    local project_hash = hash_path(project_root)
    data_file = tracking_dir .. "/" .. project_hash .. ".json"

    -- Update manifest for debugging
    local manifest_file = tracking_dir .. "/manifest.json"
    local manifest = {}

    -- Load existing manifest
    local f = io.open(manifest_file, "r")
    if f then
      local content = f:read("*a")
      f:close()
      local ok, data = pcall(vim.json.decode, content)
      if ok and type(data) == "table" then
        manifest = data
      end
    end

    -- Update manifest with current project
    manifest[project_hash] = project_root

    -- Save manifest
    local ok, json = pcall(vim.json.encode, manifest)
    if ok then
      f = io.open(manifest_file, "w")
      if f then
        f:write(json)
        f:close()
      end
    end

    -- Clear buffer_data (caller will reload)
    buffer_data = {}
  end

  return data_file
end

-- Helper to ensure buffer exists in tracking
local function ensure_buffer(filepath)
  if not buffer_data[filepath] then
    buffer_data[filepath] = { access = 0, saves = 0 }
  end
end

-- Load data from JSON file
local function load_from_json()
  local file_path = get_data_file()
  local file = io.open(file_path, "r")
  if file then
    local content = file:read("*a")
    file:close()

    local ok, data = pcall(vim.json.decode, content)
    if ok and type(data) == "table" then
      buffer_data = data
      return true
    end
  end
  return false
end

-- Save data to JSON file
local function save_to_json()
  local file_path = get_data_file()
  local ok, json = pcall(vim.json.encode, buffer_data)
  if not ok then
    return false
  end

  local file = io.open(file_path, "w")
  if file then
    file:write(json)
    file:close()
    return true
  end
  return false
end

-- Debounced save - only saves after 2 seconds of inactivity
local function debounced_save()
  -- Cancel any pending save
  if save_timer then
    vim.fn.timer_stop(save_timer)
  end

  -- Schedule new save for 2 seconds from now
  save_timer = vim.fn.timer_start(2000, function()
    save_to_json()
    save_timer = nil
  end)
end

-- Initialize
function M.setup()
  if M.initialized then
    return
  end

  -- Load existing data for this project (get_data_file will handle initialization)
  if load_from_json() then
    vim.notify("Buffer tracking loaded for project: " .. vim.fn.fnamemodify(current_project_root, ":t"), vim.log.levels.INFO)
  else
    vim.notify("Buffer tracking initialized for project: " .. vim.fn.fnamemodify(current_project_root, ":t"), vim.log.levels.INFO)
  end

  local augroup = vim.api.nvim_create_augroup("SimpleBufferImportance", { clear = true })

  -- Track buffer access
  vim.api.nvim_create_autocmd("BufEnter", {
    group = augroup,
    callback = function()
      M.track_access(vim.api.nvim_buf_get_name(0))
    end
  })

  -- Track saves
  vim.api.nvim_create_autocmd("BufWritePost", {
    group = augroup,
    callback = function()
      M.track_save(vim.api.nvim_buf_get_name(0))
    end
  })

  -- Save on exit (cancel any pending debounced save and save immediately)
  vim.api.nvim_create_autocmd("VimLeavePre", {
    group = augroup,
    callback = function()
      if save_timer then
        vim.fn.timer_stop(save_timer)
        save_timer = nil
      end
      save_to_json()
    end
  })

  -- Detect directory changes to switch project contexts
  vim.api.nvim_create_autocmd("DirChanged", {
    group = augroup,
    callback = function()
      -- Save current project data before switching
      if save_timer then
        vim.fn.timer_stop(save_timer)
        save_timer = nil
      end
      save_to_json()

      -- Check if we've switched projects
      local new_project = detect_project_root()
      if new_project ~= current_project_root then
        -- get_data_file() will set up the new project's data file
        get_data_file()
        -- Reload the new project's data
        load_from_json()
        vim.notify("Switched to project: " .. vim.fn.fnamemodify(new_project, ":t"), vim.log.levels.INFO)
      end
    end
  })

  M.initialized = true
end

-- Track buffer access
function M.track_access(filepath)
  if filepath == "" or filepath:match("^%[") then
    return -- Skip special buffers
  end

  ensure_buffer(filepath)
  buffer_data[filepath].access = buffer_data[filepath].access + 1
  debounced_save()
end

-- Track buffer saves
function M.track_save(filepath)
  if filepath == "" or filepath:match("^%[") then
    return
  end

  ensure_buffer(filepath)
  buffer_data[filepath].saves = buffer_data[filepath].saves + 1
  debounced_save() -- Debounced to avoid blocking on every save
end

-- Calculate importance score
-- Weights: 60% access, 40% saves
local function calculate_score(access, saves)
  local normalized = {
    access = math.min(access / 10, 1),  -- Cap at 10 accesses
    saves = math.min(saves / 10, 1),     -- Cap at 10 saves
  }

  return (normalized.access * 0.6) + (normalized.saves * 0.4)
end

-- Get all tracked buffers
function M.get_all()
  if not M.initialized then
    return {}
  end

  local results = {}

  for filepath, data in pairs(buffer_data) do
    local score = calculate_score(data.access, data.saves)
    table.insert(results, {
      filepath = filepath,
      access = data.access,
      saves = data.saves,
      score = score
    })
  end

  -- Sort by importance score
  table.sort(results, function(a, b) return a.score > b.score end)

  return results
end

-- Get stats for specific buffer
function M.get_stats(filepath)
  if not M.initialized then
    return nil
  end

  if buffer_data[filepath] then
    local data = buffer_data[filepath]
    local score = calculate_score(data.access, data.saves)
    return {
      access = data.access,
      saves = data.saves,
      score = score
    }
  end

  return nil
end

return M