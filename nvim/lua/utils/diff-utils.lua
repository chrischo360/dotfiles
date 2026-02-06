-- Advanced diff utilities for branch comparison
-- Place this in ~/.config/nvim/lua/utils/diff-utils.lua

local M = {}

-- Get current git remote URL (GitHub)
local function get_github_url()
  local handle = io.popen("git remote get-url origin 2>/dev/null")
  if not handle then return nil end
  local url = handle:read("*a"):gsub("%s+$", "")
  handle:close()
  
  if url == "" then return nil end
  
  -- Convert SSH to HTTPS format
  url = url:gsub("git@github%.com:", "https://github.com/")
  url = url:gsub("%.git$", "")
  return url
end

-- Get current branch
local function get_current_branch()
  local handle = io.popen("git rev-parse --abbrev-ref HEAD 2>/dev/null")
  if not handle then return nil end
  local branch = handle:read("*a"):gsub("%s+$", "")
  handle:close()
  return branch ~= "" and branch or nil
end

-- Get current commit SHA
local function get_current_sha()
  local handle = io.popen("git rev-parse HEAD 2>/dev/null")
  if not handle then return nil end
  local sha = handle:read("*a"):gsub("%s+$", "")
  handle:close()
  return sha ~= "" and sha or nil
end

-- Copy GitHub permalink to clipboard
function M.copy_github_permalink()
  local github_url = get_github_url()
  if not github_url then
    vim.notify("Not a GitHub repository", vim.log.levels.WARN)
    return
  end
  
  local sha = get_current_sha()
  if not sha then
    vim.notify("Could not get commit SHA", vim.log.levels.WARN)
    return
  end
  
  local file = vim.fn.expand("%:.")
  if file == "" then
    vim.notify("No file is currently open", vim.log.levels.WARN)
    return
  end
  
  local line = vim.fn.line(".")
  local permalink = string.format("%s/blob/%s/%s#L%d", github_url, sha, file, line)
  
  vim.fn.setreg("+", permalink)
  vim.notify("Copied: " .. permalink, vim.log.levels.INFO)
end

-- Copy GitHub permalink for visual selection (line range)
function M.copy_github_permalink_range()
  local github_url = get_github_url()
  if not github_url then
    vim.notify("Not a GitHub repository", vim.log.levels.WARN)
    return
  end
  
  local sha = get_current_sha()
  if not sha then
    vim.notify("Could not get commit SHA", vim.log.levels.WARN)
    return
  end
  
  local file = vim.fn.expand("%:.")
  if file == "" then
    vim.notify("No file is currently open", vim.log.levels.WARN)
    return
  end
  
  local start_line = vim.fn.line("'<")
  local end_line = vim.fn.line("'>")
  
  local permalink
  if start_line == end_line then
    permalink = string.format("%s/blob/%s/%s#L%d", github_url, sha, file, start_line)
  else
    permalink = string.format("%s/blob/%s/%s#L%d-L%d", github_url, sha, file, start_line, end_line)
  end
  
  vim.fn.setreg("+", permalink)
  vim.notify("Copied: " .. permalink, vim.log.levels.INFO)
end

-- Open current file on GitHub in browser
function M.open_on_github()
  local github_url = get_github_url()
  if not github_url then
    vim.notify("Not a GitHub repository", vim.log.levels.WARN)
    return
  end
  
  local branch = get_current_branch()
  if not branch then
    vim.notify("Could not get current branch", vim.log.levels.WARN)
    return
  end
  
  local file = vim.fn.expand("%:.")
  if file == "" then
    vim.notify("No file is currently open", vim.log.levels.WARN)
    return
  end
  
  local line = vim.fn.line(".")
  local url = string.format("%s/blob/%s/%s#L%d", github_url, branch, file, line)
  
  -- Open in browser (macOS)
  vim.fn.system({"open", url})
  vim.notify("Opened in browser", vim.log.levels.INFO)
end

-- Open a GitHub PR in diffview (parse URL and open locally)
function M.open_pr_diff()
  -- Get URL from clipboard or prompt
  vim.ui.input({
    prompt = "GitHub PR URL: ",
    default = vim.fn.getreg("+"),
  }, function(url)
    if not url or url == "" then return end
    
    -- Parse PR URL: https://github.com/owner/repo/pull/123
    local owner, repo, pr_num = url:match("github%.com/([^/]+)/([^/]+)/pull/(%d+)")
    if not owner or not repo or not pr_num then
      vim.notify("Invalid GitHub PR URL", vim.log.levels.ERROR)
      return
    end
    
    -- Fetch PR info using gh CLI
    local cmd = string.format("gh pr view %s --repo %s/%s --json baseRefName,headRefName 2>/dev/null", pr_num, owner, repo)
    local handle = io.popen(cmd)
    if not handle then
      vim.notify("Failed to fetch PR info (is gh CLI installed?)", vim.log.levels.ERROR)
      return
    end
    
    local result = handle:read("*a")
    handle:close()
    
    local ok, data = pcall(vim.json.decode, result)
    if not ok or not data then
      vim.notify("Failed to parse PR info", vim.log.levels.ERROR)
      return
    end
    
    -- Open diffview comparing base..head
    local diff_cmd = string.format("DiffviewOpen %s..%s", data.baseRefName, data.headRefName)
    vim.cmd(diff_cmd)
    vim.notify(string.format("Opened PR #%s: %s → %s", pr_num, data.headRefName, data.baseRefName), vim.log.levels.INFO)
  end)
end

-- Get list of git branches
local function get_git_branches()
  local handle = io.popen('git branch --format="%(refname:short)"')
  if not handle then
    return {}
  end

  local branches = {}
  for line in handle:lines() do
    if line and line ~= "" then
      table.insert(branches, line)
    end
  end
  handle:close()
  return branches
end

-- Get recent commits
local function get_recent_commits(count)
  count = count or 10
  local handle = io.popen("git log --oneline -n " .. count .. ' --format="%h %s"')
  if not handle then
    return {}
  end

  local commits = {}
  for line in handle:lines() do
    if line and line ~= "" then
      table.insert(commits, line)
    end
  end
  handle:close()
  return commits
end

-- Interactive branch selector
function M.compare_branches_interactive()
  local branches = get_git_branches()
  if #branches == 0 then
    vim.notify("No git branches found", vim.log.levels.WARN)
    return
  end

  vim.ui.select(branches, {
    prompt = "Select first branch to compare:",
  }, function(branch1)
    if not branch1 then
      return
    end

    vim.ui.select(branches, {
      prompt = "Select second branch to compare:",
    }, function(branch2)
      if not branch2 then
        return
      end

      if branch1 == branch2 then
        vim.notify("Cannot compare branch with itself", vim.log.levels.WARN)
        return
      end

      vim.cmd("DiffviewOpen " .. branch1 .. ".." .. branch2)
    end)
  end)
end

-- Compare current branch with another
function M.compare_with_branch_interactive()
  local branches = get_git_branches()
  if #branches == 0 then
    vim.notify("No git branches found", vim.log.levels.WARN)
    return
  end

  vim.ui.select(branches, {
    prompt = "Select branch to compare with current:",
  }, function(branch)
    if not branch then
      return
    end
    vim.cmd("DiffviewOpen " .. branch)
  end)
end

-- Compare with specific commit
function M.compare_with_commit_interactive()
  local commits = get_recent_commits(20)
  if #commits == 0 then
    vim.notify("No git commits found", vim.log.levels.WARN)
    return
  end

  vim.ui.select(commits, {
    prompt = "Select commit to compare with:",
  }, function(commit)
    if not commit then
      return
    end
    local hash = commit:match("^(%w+)")
    if hash then
      vim.cmd("DiffviewOpen " .. hash)
    end
  end)
end

-- Compare current file between branches
function M.compare_file_between_branches()
  local current_file = vim.fn.expand("%:.")
  if current_file == "" then
    vim.notify("No file is currently open", vim.log.levels.WARN)
    return
  end

  local branches = get_git_branches()
  if #branches == 0 then
    vim.notify("No git branches found", vim.log.levels.WARN)
    return
  end

  vim.ui.select(branches, {
    prompt = "Select first branch:",
  }, function(branch1)
    if not branch1 then
      return
    end

    vim.ui.select(branches, {
      prompt = "Select second branch:",
    }, function(branch2)
      if not branch2 then
        return
      end

      if branch1 == branch2 then
        vim.notify("Cannot compare branch with itself", vim.log.levels.WARN)
        return
      end

      vim.cmd("DiffviewOpen " .. branch1 .. ".." .. branch2 .. " -- " .. current_file)
    end)
  end)
end

-- Show file history with better filtering
function M.file_history_advanced()
  local current_file = vim.fn.expand("%:.")
  if current_file == "" then
    vim.notify("No file is currently open", vim.log.levels.WARN)
    return
  end

  local options = {
    "All commits for this file",
    "Last 10 commits for this file",
    "Last 50 commits for this file",
    "Commits in current branch only",
    "Commits from all branches",
  }

  vim.ui.select(options, {
    prompt = "File history options:",
  }, function(choice)
    if not choice then
      return
    end

    local cmd = "DiffviewFileHistory "

    if choice:match("Last 10") then
      cmd = cmd .. "--max-count=10 "
    elseif choice:match("Last 50") then
      cmd = cmd .. "--max-count=50 "
    elseif choice:match("current branch") then
      cmd = cmd .. "--branches=HEAD "
    elseif choice:match("all branches") then
      cmd = cmd .. "--all "
    end

    cmd = cmd .. current_file
    vim.cmd(cmd)
  end)
end

-- Quick compare with main/master branch
function M.compare_with_main()
  -- Try main first, then master
  local handle = io.popen("git rev-parse --verify main 2>/dev/null")
  if handle then
    local result = handle:read("*a")
    handle:close()
    if result and result ~= "" then
      vim.cmd("DiffviewOpen main")
      return
    end
  end

  -- Fallback to master
  handle = io.popen("git rev-parse --verify master 2>/dev/null")
  if handle then
    local result = handle:read("*a")
    handle:close()
    if result and result ~= "" then
      vim.cmd("DiffviewOpen master")
      return
    end
  end

  vim.notify("Neither 'main' nor 'master' branch found", vim.log.levels.WARN)
end

-- Quick diff commands
function M.quick_diff_menu()
  local options = {
    "Compare with main/master",
    "Compare with develop",
    "Compare with HEAD~1",
    "Compare with HEAD~5",
    "Compare with HEAD~10",
    "Compare branches (interactive)",
    "Compare with commit (interactive)",
    "File history (current file)",
    "File history (advanced)",
  }

  vim.ui.select(options, {
    prompt = "Quick diff options:",
  }, function(choice)
    if not choice then
      return
    end

    if choice:match("Compare with main") then
      -- Try main first, then master
      local handle = io.popen("git rev-parse --verify main 2>/dev/null")
      if handle then
        local result = handle:read("*a")
        handle:close()
        if result and result ~= "" then
          vim.cmd("DiffviewOpen main")
        else
          vim.cmd("DiffviewOpen master")
        end
      end
    elseif choice:match("Compare with develop") then
      vim.cmd("DiffviewOpen develop")
    elseif choice:match("HEAD~1") then
      vim.cmd("DiffviewOpen HEAD~1")
    elseif choice:match("HEAD~5") then
      vim.cmd("DiffviewOpen HEAD~5")
    elseif choice:match("HEAD~10") then
      vim.cmd("DiffviewOpen HEAD~10")
    elseif choice:match("Compare branches") then
      M.compare_branches_interactive()
    elseif choice:match("Compare with commit") then
      M.compare_with_commit_interactive()
    elseif choice:match("File history %(current file%)") then
      vim.cmd("DiffviewFileHistory %")
    elseif choice:match("File history %(advanced%)") then
      M.file_history_advanced()
    end
  end)
end

-- Setup keymaps for these utilities
function M.setup_keymaps()
  local opts = { noremap = true, silent = true }

  -- Quick shortcuts
  vim.keymap.set(
    "n",
    "<leader>dm",
    M.compare_with_main,
    vim.tbl_extend("force", opts, { desc = "Compare with main/master" })
  )

  vim.keymap.set("n", "<leader>dq", M.quick_diff_menu, vim.tbl_extend("force", opts, { desc = "Quick Diff Menu" }))

  -- Interactive selectors
  vim.keymap.set(
    "n",
    "<leader>db",
    M.compare_with_branch_interactive,
    vim.tbl_extend("force", opts, { desc = "Compare current with branch" })
  )

  vim.keymap.set(
    "n",
    "<leader>d2b",
    M.compare_branches_interactive,
    vim.tbl_extend("force", opts, { desc = "Compare two branches" })
  )

  -- GitHub link utilities
  vim.keymap.set(
    "n",
    "<leader>gy",
    M.copy_github_permalink,
    vim.tbl_extend("force", opts, { desc = "Copy GitHub permalink" })
  )

  vim.keymap.set(
    "v",
    "<leader>gy",
    M.copy_github_permalink_range,
    vim.tbl_extend("force", opts, { desc = "Copy GitHub permalink (selection)" })
  )

  vim.keymap.set(
    "n",
    "<leader>go",
    M.open_on_github,
    vim.tbl_extend("force", opts, { desc = "Open file on GitHub" })
  )

  vim.keymap.set(
    "n",
    "<leader>gp",
    M.open_pr_diff,
    vim.tbl_extend("force", opts, { desc = "Open GitHub PR in diffview" })
  )
end

return M
