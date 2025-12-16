-- Git & Diffview Performance Profiler
local M = {}

-- Profile git commands
function M.profile_git_commands()
  local results = {}

  -- Get current directory
  local cwd = vim.fn.getcwd()
  results.cwd = cwd

  -- Count objects
  local count_cmd = "git rev-list --all --count 2>/dev/null"
  local handle = io.popen(count_cmd)
  if handle then
    results.commit_count = handle:read("*a"):gsub("%s+", "")
    handle:close()
  end

  -- Count changed files
  local diff_stat_cmd = "git diff --numstat 2>/dev/null | wc -l"
  handle = io.popen(diff_stat_cmd)
  if handle then
    results.changed_files = handle:read("*a"):gsub("%s+", "")
    handle:close()
  end

  -- Time git diff
  local start = vim.loop.hrtime()
  local git_diff_cmd = "git diff --name-status 2>/dev/null"
  handle = io.popen(git_diff_cmd)
  if handle then
    local output = handle:read("*a")
    handle:close()
    local git_diff_time = (vim.loop.hrtime() - start) / 1e6
    results.git_diff_ms = string.format("%.2f", git_diff_time)
    results.git_diff_output_size = #output
  end

  -- Time git log
  start = vim.loop.hrtime()
  local git_log_cmd = "git log --oneline -n 100 2>/dev/null"
  handle = io.popen(git_log_cmd)
  if handle then
    handle:read("*a")
    handle:close()
    local git_log_time = (vim.loop.hrtime() - start) / 1e6
    results.git_log_ms = string.format("%.2f", git_log_time)
  end

  return results
end

-- Display profiling results
function M.show_profile()
  local results = M.profile_git_commands()

  local lines = {
    "=== Git Performance Profile ===",
    "",
    "Repository: " .. results.cwd,
    "Total commits: " .. (results.commit_count or "unknown"),
    "Changed files: " .. (results.changed_files or "0"),
    "",
    "Git command timings:",
    "  git diff --name-status: " .. (results.git_diff_ms or "N/A") .. " ms",
    "  git log -n 100: " .. (results.git_log_ms or "N/A") .. " ms",
    "  diff output size: " .. (results.git_diff_output_size or "0") .. " bytes",
    "",
  }

  -- Check for slowness
  local diff_time = tonumber(results.git_diff_ms)
  if diff_time and diff_time > 500 then
    table.insert(lines, "⚠️  WARNING: git diff is slow (>" .. diff_time .. "ms)")
    table.insert(lines, "   This indicates git itself is the bottleneck, not Neovim.")
    table.insert(lines, "   Consider: working tree cleanup, .gitignore optimization")
  elseif diff_time and diff_time > 100 then
    table.insert(lines, "⚠️  NOTICE: git diff is moderately slow (" .. diff_time .. "ms)")
  else
    table.insert(lines, "✓ Git operations are fast")
  end

  table.insert(lines, "")
  table.insert(lines, "Now test :DiffviewOpen and check the timing message...")

  -- Open results in a floating window
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

  local width = 70
  local height = #lines + 2
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    col = (vim.o.columns - width) / 2,
    row = (vim.o.lines - height) / 2,
    style = "minimal",
    border = "rounded",
  })

  vim.api.nvim_buf_set_option(buf, "modifiable", false)
  vim.api.nvim_buf_set_keymap(buf, "n", "q", ":close<CR>", { noremap = true, silent = true })
  vim.api.nvim_buf_set_keymap(buf, "n", "<Esc>", ":close<CR>", { noremap = true, silent = true })
end

return M
