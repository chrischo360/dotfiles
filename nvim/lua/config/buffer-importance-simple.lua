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

-- Track current branch
local current_branch = nil

-- Detect git branch (returns nil if not a git repo)
local function detect_git_branch()
  local git_dir = vim.fn.systemlist("git -C " .. vim.fn.shellescape(vim.fn.getcwd()) .. " rev-parse --git-dir")[1]
  if vim.v.shell_error ~= 0 then
    return nil
  end

  -- Try symbolic ref first (normal branches)
  local branch = vim.fn.systemlist("git -C " .. vim.fn.shellescape(vim.fn.getcwd()) .. " symbolic-ref --short HEAD")[1]
  if vim.v.shell_error == 0 and branch and branch ~= "" then
    return branch
  end

  -- Detached HEAD - use short SHA
  local sha = vim.fn.systemlist("git -C " .. vim.fn.shellescape(vim.fn.getcwd()) .. " rev-parse --short HEAD")[1]
  if vim.v.shell_error == 0 and sha and sha ~= "" then
    return "detached-" .. sha
  end

  return nil
end

-- Detect main branch for a project
local function detect_main_branch(project_root)
  -- Try git config
  local default = vim.fn.systemlist("git -C " .. vim.fn.shellescape(project_root) .. " config --get init.defaultBranch")[1]
  if vim.v.shell_error == 0 and default and default ~= "" then
    return default
  end

  -- Try remote HEAD
  local remote_head = vim.fn.systemlist("git -C " .. vim.fn.shellescape(project_root) .. " symbolic-ref refs/remotes/origin/HEAD")[1]
  if vim.v.shell_error == 0 and remote_head and remote_head ~= "" then
    return remote_head:gsub("^refs/remotes/origin/", "")
  end

  -- Check if main or master exists
  local has_main = vim.fn.systemlist("git -C " .. vim.fn.shellescape(project_root) .. " show-ref --verify refs/heads/main")[1]
  if vim.v.shell_error == 0 then
    return "main"
  end

  local has_master = vim.fn.systemlist("git -C " .. vim.fn.shellescape(project_root) .. " show-ref --verify refs/heads/master")[1]
  if vim.v.shell_error == 0 then
    return "master"
  end

  return "main" -- fallback
end

-- Update manifest with enhanced metadata
local function update_manifest(tracking_dir, project_hash, project_root, branch, main_branch)
  local manifest_file = tracking_dir .. "/manifest.json"
  local manifest = {}

  -- Load existing manifest
  local f = io.open(manifest_file, "r")
  if f then
    local content = f:read("*a")
    f:close()
    local ok, data = pcall(vim.json.decode, content)
    if ok and type(data) == "table" then
      -- Handle old format (string values) - migrate to new format
      for hash, value in pairs(data) do
        if type(value) == "string" then
          manifest[hash] = {
            project_root = value,
            main_branch = "main",
            branches = {},
            last_accessed = os.date("!%Y-%m-%dT%H:%M:%SZ")
          }
        else
          manifest[hash] = value
        end
      end
    end
  end

  -- Update manifest entry
  if not manifest[project_hash] then
    manifest[project_hash] = {
      project_root = project_root,
      main_branch = main_branch,
      branches = {},
      last_accessed = os.date("!%Y-%m-%dT%H:%M:%SZ")
    }
  else
    manifest[project_hash].last_accessed = os.date("!%Y-%m-%dT%H:%M:%SZ")
  end

  -- Add branch to list if not present
  if branch and not vim.tbl_contains(manifest[project_hash].branches, branch) then
    table.insert(manifest[project_hash].branches, branch)
  end

  -- Save manifest
  local ok, json = pcall(vim.json.encode, manifest)
  if ok then
    f = io.open(manifest_file, "w")
    if f then
      f:write(json)
      f:close()
    end
  end
end

-- Simple hash function to create unique filename from path
local function hash_path(path)
  local hash = 0
  for i = 1, #path do
    hash = (hash * 31 + string.byte(path, i)) % 1000000
  end
  return string.format("project-%06d", hash)
end

-- Get project directory and branch-specific file path
local function get_project_dir_and_file()
  local project_root = detect_project_root()

  -- If project changed, set up new data file
  if project_root ~= current_project_root then
    current_project_root = project_root

    -- Create tracking directory if it doesn't exist
    local tracking_dir = vim.fn.stdpath("data") .. "/buffer_tracking"
    vim.fn.mkdir(tracking_dir, "p")

    -- Generate project-specific directory
    local project_hash = hash_path(project_root)
    local project_dir = tracking_dir .. "/" .. project_hash
    vim.fn.mkdir(project_dir, "p")

    -- Detect git branch (nil if not a git repo)
    local branch = detect_git_branch()
    local main_branch = detect_main_branch(project_root)

    -- Migration: Move old project-XXXXXX.json → project-XXXXXX/main.json
    local old_file = tracking_dir .. "/" .. project_hash .. ".json"
    local main_file = project_dir .. "/" .. main_branch .. ".json"
    if vim.fn.filereadable(old_file) == 1 and vim.fn.filereadable(main_file) == 0 then
      vim.fn.rename(old_file, main_file)
      vim.notify("Migrated tracking data to new branch-aware structure", vim.log.levels.INFO)
    end

    -- Set data file based on branch (or main if not git)
    if branch then
      data_file = project_dir .. "/" .. branch .. ".json"
      current_branch = branch
    else
      data_file = project_dir .. "/" .. main_branch .. ".json"
      current_branch = main_branch
    end

    -- Update manifest
    update_manifest(tracking_dir, project_hash, project_root, branch, main_branch)

    -- Clear buffer_data (caller will reload)
    buffer_data = {}
  end

  return vim.fn.fnamemodify(data_file, ":h"), current_branch
end

-- Helper to ensure buffer exists in tracking
local function ensure_buffer(filepath)
  if not buffer_data[filepath] then
    buffer_data[filepath] = { access = 0, saves = 0 }
  end
end

-- Load data from JSON file (with inheritance from main branch)
local function load_from_json()
  local project_dir, branch = get_project_dir_and_file()
  local branch_file = data_file

  -- Try loading branch file
  local file = io.open(branch_file, "r")
  if file then
    local content = file:read("*a")
    file:close()

    local ok, data = pcall(vim.json.decode, content)
    if ok and type(data) == "table" then
      buffer_data = data
      return true
    end
  end

  -- Branch file doesn't exist - try inheriting from main
  if current_project_root then
    local main_branch = detect_main_branch(current_project_root)
    if branch ~= main_branch then
      local main_file = project_dir .. "/" .. main_branch .. ".json"
      file = io.open(main_file, "r")
      if file then
        local content = file:read("*a")
        file:close()

        local ok, data = pcall(vim.json.decode, content)
        if ok and type(data) == "table" then
          buffer_data = data
          local count = 0
          for _ in pairs(data) do count = count + 1 end
          vim.notify("Inherited " .. count .. " buffers from " .. main_branch, vim.log.levels.INFO)
          return true
        end
      end
    end
  end

  return false
end

-- Save data to JSON file
local function save_to_json()
  local ok, json = pcall(vim.json.encode, buffer_data)
  if not ok then
    return false
  end

  local file = io.open(data_file, "w")
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
        -- get_project_dir_and_file() will set up the new project's data file
        get_project_dir_and_file()
        -- Reload the new project's data
        load_from_json()
        vim.notify("Switched to project: " .. vim.fn.fnamemodify(new_project, ":t"), vim.log.levels.INFO)
      end
    end
  })

  -- Detect branch changes (when user switches branches outside nvim)
  vim.api.nvim_create_autocmd("FocusGained", {
    group = augroup,
    callback = function()
      -- Check if branch changed
      local new_branch = detect_git_branch()
      if new_branch and new_branch ~= current_branch then
        -- Save current branch data
        if save_timer then
          vim.fn.timer_stop(save_timer)
          save_timer = nil
        end
        save_to_json()

        -- Switch to new branch
        local project_dir = vim.fn.fnamemodify(data_file, ":h")
        data_file = project_dir .. "/" .. new_branch .. ".json"
        current_branch = new_branch

        -- Update manifest
        local tracking_dir = vim.fn.stdpath("data") .. "/buffer_tracking"
        local project_hash = hash_path(current_project_root)
        local main_branch = detect_main_branch(current_project_root)
        update_manifest(tracking_dir, project_hash, current_project_root, new_branch, main_branch)

        -- Reload data (with inheritance if needed)
        buffer_data = {}
        load_from_json()
        vim.notify("Switched to branch: " .. new_branch, vim.log.levels.INFO)
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

-- Get all tracked buffers (with merge from main if on feature branch)
function M.get_all()
  if not M.initialized then
    return {}
  end

  local results = {}

  -- Add all buffers from current branch
  for filepath, data in pairs(buffer_data) do
    local score = calculate_score(data.access, data.saves)
    table.insert(results, {
      filepath = filepath,
      access = data.access,
      saves = data.saves,
      score = score,
      from_main = false
    })
  end

  -- If on feature branch, merge high-importance files from main
  if current_project_root and current_branch then
    local main_branch = detect_main_branch(current_project_root)
    if current_branch ~= main_branch then
      local project_dir = vim.fn.fnamemodify(data_file, ":h")
      local main_file = project_dir .. "/" .. main_branch .. ".json"

      -- Try to read main branch data
      local f = io.open(main_file, "r")
      if f then
        local content = f:read("*a")
        f:close()

        local ok, main_data = pcall(vim.json.decode, content)
        if ok and type(main_data) == "table" then
          -- Create lookup of current branch files
          local current_files = {}
          for filepath, _ in pairs(buffer_data) do
            current_files[filepath] = true
          end

          -- Add high-importance files from main (score >= 0.5, not in feature branch)
          for filepath, data in pairs(main_data) do
            if not current_files[filepath] then
              local score = calculate_score(data.access, data.saves)
              if score >= 0.5 then
                table.insert(results, {
                  filepath = filepath,
                  access = data.access,
                  saves = data.saves,
                  score = score,
                  from_main = true
                })
              end
            end
          end
        end
      end
    end
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