-- Custom commands for note-taking workflow

local notes_dir = vim.fn.expand("~/notes")

-- Archive weekly plan with automatic naming
vim.api.nvim_create_user_command("ArchivePlan", function()
  local week = os.date("%V")
  local date = os.date("%Y-%b-%d"):lower()
  local new_name = string.format("2025-week-%s_%s.md", week, date)

  local source = vim.fn.expand("~/notes/plans/week.md")
  local target = vim.fn.expand("~/notes/plans/archive/" .. new_name)

  -- Check if source file exists
  if vim.fn.filereadable(source) == 0 then
    vim.notify("Error: week.md not found", vim.log.levels.ERROR)
    return
  end

  -- Move the file
  local result = vim.fn.rename(source, target)
  if result == 0 then
    vim.notify("✓ Archived to: " .. new_name, vim.log.levels.INFO)
  else
    vim.notify("Error: Failed to archive plan", vim.log.levels.ERROR)
  end
end, { desc = "Archive week.md with date naming" })

-- Create new weekly plan from template
vim.api.nvim_create_user_command("NewPlan", function()
  local week = os.date("%V")
  local year = os.date("%Y")

  -- Calculate start and end dates for the week (Monday-Friday)
  local today = os.time()
  local day_of_week = tonumber(os.date("%w", today)) -- 0=Sunday, 1=Monday, etc.
  local days_to_monday = (day_of_week == 0) and -6 or (1 - day_of_week)

  local monday = os.time() + (days_to_monday * 24 * 60 * 60)
  local friday = monday + (4 * 24 * 60 * 60)

  local start_date = os.date("%m/%d/%Y", monday)
  local end_date = os.date("%m/%d/%Y", friday)

  local template_path = vim.fn.fnamemodify("~/notes/plans/template/week.md", ":p")
  local target_path = vim.fn.fnamemodify("~/notes/plans/week.md", ":p")

  -- Check if template exists
  if vim.fn.filereadable(template_path) == 0 then
    vim.notify("Error: Template file not found", vim.log.levels.ERROR)
    return
  end

  -- Check if week.md already exists
  if vim.fn.filereadable(target_path) == 1 then
    vim.notify("Error: week.md already exists. Archive it first with :ArchivePlan", vim.log.levels.WARN)
    return
  end

  -- Read template
  local template_lines = vim.fn.readfile(template_path)

  -- Replace the first line with actual week info
  if #template_lines > 0 then
    template_lines[1] = string.format("**Week %s: %s - %s**", week, start_date, end_date)
  end

  -- Write new file
  vim.fn.writefile(template_lines, target_path)

  vim.notify(string.format("✓ Created week.md for Week %s (%s - %s)", week, start_date, end_date), vim.log.levels.INFO)

  -- Open the new file
  vim.cmd("edit " .. target_path)
end, { desc = "Create new week.md from template" })

-- Create new ticket directory
vim.api.nvim_create_user_command("NewTicket", function(opts)
  local args = vim.split(opts.args, "%s+")
  local ticket_num = args[1]
  local custom_name = args[2]

  if not ticket_num or ticket_num == "" then
    vim.notify("Error: Please provide ticket number (e.g., :NewTicket PGL-629)", vim.log.levels.ERROR)
    return
  end

  -- Validate ticket format (PGL-XXX)
  if not ticket_num:match("^PGL%-%d+$") then
    vim.notify("Error: Ticket must be in format PGL-XXX (e.g., PGL-629)", vim.log.levels.ERROR)
    return
  end

  local ticket_dir = vim.fn.fnamemodify("~/notes/work/" .. ticket_num, ":p")
  local template_path = vim.fn.fnamemodify("~/notes/work/__TEMPLATE[pgl-000]_TICKET_NAME.md]__.md", ":p")

  -- Check if ticket directory already exists
  if vim.fn.isdirectory(ticket_dir) == 1 then
    vim.notify("Error: Ticket " .. ticket_num .. " already exists", vim.log.levels.WARN)
    return
  end

  -- Check if template exists
  if vim.fn.filereadable(template_path) == 0 then
    vim.notify("Error: Template file not found", vim.log.levels.ERROR)
    return
  end

  -- Create ticket directory
  vim.fn.mkdir(ticket_dir, "p")

  -- Determine filename
  local filename
  if custom_name and custom_name ~= "" then
    filename = custom_name:gsub("-", "_") .. ".md"
  else
    -- Convert PGL-629 to pgl_629.md
    filename = ticket_num:lower():gsub("-", "_") .. ".md"
  end

  local target_file = ticket_dir .. filename

  -- Copy template to new file
  local template_lines = vim.fn.readfile(template_path)
  vim.fn.writefile(template_lines, target_file)

  vim.notify("✓ Created ticket: " .. ticket_num .. "/" .. filename, vim.log.levels.INFO)

  -- Open the new file
  vim.cmd("edit " .. target_file)
end, { nargs = "+", desc = "Create new ticket directory from template" })

-- Archive ticket directory
vim.api.nvim_create_user_command("ArchiveTicket", function(opts)
  local ticket_num = opts.args

  if not ticket_num or ticket_num == "" then
    vim.notify("Error: Please provide ticket number (e.g., :ArchiveTicket PGL-629)", vim.log.levels.ERROR)
    return
  end

  -- Validate ticket format (PGL-XXX)
  if not ticket_num:match("^PGL%-%d+$") then
    vim.notify("Error: Ticket must be in format PGL-XXX (e.g., PGL-629)", vim.log.levels.ERROR)
    return
  end

  local source_dir = vim.fn.fnamemodify("~/notes/work/" .. ticket_num, ":p")
  local archive_base = vim.fn.fnamemodify("~/notes/work/archive", ":p")
  local target_dir = archive_base .. ticket_num

  -- Check if source directory exists
  if vim.fn.isdirectory(source_dir) == 0 then
    vim.notify("Error: Ticket directory not found: " .. ticket_num, vim.log.levels.ERROR)
    return
  end

  -- Create archive directory if it doesn't exist
  vim.fn.mkdir(archive_base, "p")

  -- Move the directory
  local result = vim.fn.rename(source_dir, target_dir)
  if result == 0 then
    vim.notify("✓ Archived " .. ticket_num .. " to archive/", vim.log.levels.INFO)
  else
    vim.notify("Error: Failed to archive ticket", vim.log.levels.ERROR)
  end
end, { nargs = 1, desc = "Archive ticket directory" })

-- Create new meeting note
vim.api.nvim_create_user_command("NewMeeting", function(opts)
  local meeting_name = opts.args

  if not meeting_name or meeting_name == "" then
    vim.notify("Error: Please provide meeting name (e.g., :NewMeeting mike-1on1)", vim.log.levels.ERROR)
    return
  end

  local date = os.date("%Y-%m-%d")
  local filename = string.format("%s_%s.md", date, meeting_name)
  local meetings_dir = vim.fn.fnamemodify("~/notes/meetings", ":p")
  local template_path = vim.fn.fnamemodify("~/notes/meetings/template/default.md", ":p")
  local target_file = meetings_dir .. filename

  -- Create meetings directory if it doesn't exist
  vim.fn.mkdir(meetings_dir, "p")

  -- Check if file already exists
  if vim.fn.filereadable(target_file) == 1 then
    vim.notify("Error: Meeting note already exists: " .. filename, vim.log.levels.WARN)
    return
  end

  -- Check if template exists
  if vim.fn.filereadable(template_path) == 1 then
    -- Read template and substitute variables
    local template_lines = vim.fn.readfile(template_path)
    local expanded_lines = {}
    for _, line in ipairs(template_lines) do
      local expanded = line:gsub("MEETING_NAME", meeting_name):gsub("DATE", date)
      table.insert(expanded_lines, expanded)
    end
    vim.fn.writefile(expanded_lines, target_file)
    vim.notify("✓ Created meeting note: " .. filename, vim.log.levels.INFO)
  else
    -- Fallback to empty file if template missing
    vim.fn.writefile({}, target_file)
    vim.notify("✓ Created meeting note (no template found): " .. filename, vim.log.levels.WARN)
  end

  -- Open the new file
  vim.cmd("edit " .. target_file)
end, { nargs = 1, desc = "Create new meeting note with date" })

-- Auto-create meeting files referenced in markdown links on save
vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = "*.md",
  callback = function()
    local filepath = vim.api.nvim_buf_get_name(0)
    if not filepath:find(notes_dir, 1, true) then return end

    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    local meetings_dir = vim.fn.fnamemodify("~/notes/meetings", ":p")
    local template_path = vim.fn.fnamemodify("~/notes/meetings/template/default.md", ":p")

    for _, line in ipairs(lines) do
      for filename in line:gmatch("%(%.%./meetings/(.-%.[mM][dD])%)") do
        local target = meetings_dir .. filename
        if vim.fn.filereadable(target) == 0 then
          vim.fn.mkdir(meetings_dir, "p")

          -- Try to extract date and meeting name from filename pattern: YYYY-MM-DD_name.md
          local date_str, meeting_name = filename:match("(%d%d%d%d%-%d%d%-%d%d)_(.+)%.[mM][dD]$")

          -- Use template if it exists and we extracted variables
          if vim.fn.filereadable(template_path) == 1 and date_str and meeting_name then
            local template_lines = vim.fn.readfile(template_path)
            local expanded_lines = {}
            for _, tline in ipairs(template_lines) do
              local expanded = tline:gsub("MEETING_NAME", meeting_name):gsub("DATE", date_str)
              table.insert(expanded_lines, expanded)
            end
            vim.fn.writefile(expanded_lines, target)
            vim.notify("Created: " .. filename .. " (with template)")
          else
            -- Fallback to empty file
            vim.fn.writefile({}, target)
            vim.notify("Created: " .. filename)
          end
        end
      end
    end

    local scratch_dir = vim.fn.fnamemodify("~/notes/scratch/", ":p")

    for _, line in ipairs(lines) do
      for filename in line:gmatch("%(%.%./scratch/(.-%.[mM][dD])%)") do
        local target = scratch_dir .. filename
        if vim.fn.filereadable(target) == 0 then
          vim.fn.mkdir(scratch_dir, "p")
          vim.fn.writefile({ "Date: " .. os.date("%Y-%m-%d"), "" }, target)
          vim.notify("Created: " .. filename)
        end
      end
    end
  end,
})

-- Convert bare PGL-XXX ticket IDs to markdown links in the current buffer
vim.api.nvim_create_user_command("PGL", function()
  local base_url = "https://projecthub.service.csnzoo.com/browse/"
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local count = 0
  for idx, line in ipairs(lines) do
    -- Step 1: hide already-linked tickets (e.g. [PGL-937](url)) behind a placeholder
    local placeholders = {}
    local protected = line:gsub("%[PGL%-%d+%]%(https?://[^)]+%)", function(m)
      table.insert(placeholders, m)
      return "\0" .. #placeholders .. "\0"
    end)
    -- Step 2: replace bare PGL-NNN
    local linked, n = protected:gsub("PGL%-(%d+)", function(num)
      return string.format("[PGL-%s](%sPGL-%s)", num, base_url, num)
    end)
    -- Step 3: restore placeholders
    local restored = linked:gsub("\0(%d+)\0", function(i)
      return placeholders[tonumber(i)]
    end)
    lines[idx] = restored
    count = count + n
  end
  vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
  vim.notify(string.format("Linked %d ticket(s)", count), vim.log.levels.INFO)
end, { desc = "Convert bare PGL-XXX IDs to markdown links" })

-- Convert GitHub PR URL to markdown link with repo/branch name
vim.api.nvim_create_user_command("PRLink", function(opts)
  local url = opts.args
  if url == "" then
    vim.notify("Usage: :PRLink <github-pr-url>", vim.log.levels.ERROR)
    return
  end

  -- Fetch repo name and branch using gh CLI
  local cmd = string.format(
    "gh pr view %s --json headRefName,headRepository -q '[.headRepository.name, .headRefName] | join(\"/\")'",
    vim.fn.shellescape(url)
  )
  local result = vim.fn.system(cmd)

  if vim.v.shell_error ~= 0 then
    vim.notify("Failed to fetch PR info: " .. result, vim.log.levels.ERROR)
    return
  end

  -- Trim whitespace
  local label = result:gsub("^%s*(.-)%s*$", "%1")
  local markdown = string.format("[%s](%s)", label, url)

  -- Insert at cursor position
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  local line = vim.api.nvim_get_current_line()
  local new_line = line:sub(1, col) .. markdown .. line:sub(col + 1)
  vim.api.nvim_set_current_line(new_line)

  -- Move cursor to end of inserted text
  vim.api.nvim_win_set_cursor(0, { row, col + #markdown })

  vim.notify("Inserted: " .. markdown, vim.log.levels.INFO)
end, { nargs = 1, desc = "Convert GitHub PR URL to markdown link with repo/branch name" })

-- Compute a relative path (with ../) from a directory to a target file
local function relpath(target, from_dir)
  local t = vim.split(vim.fn.fnamemodify(target, ":p"), "/", { plain = true })
  local f = vim.split((vim.fn.fnamemodify(from_dir, ":p"):gsub("/$", "")), "/", { plain = true })
  local i = 1
  while i <= #f and i <= #t and f[i] == t[i] do
    i = i + 1
  end
  local parts = {}
  for _ = i, #f do
    table.insert(parts, "..")
  end
  for j = i, #t do
    table.insert(parts, t[j])
  end
  return table.concat(parts, "/")
end

-- Insert a markdown link to a fuzzy-picked file at the cursor
vim.api.nvim_create_user_command("MdLink", function()
  local ok, builtin = pcall(require, "telescope.builtin")
  if not ok then
    vim.notify("Telescope not available", vim.log.levels.ERROR)
    return
  end
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")

  local buf_dir = vim.fn.expand("%:p:h")
  local search_root = buf_dir:find(notes_dir, 1, true) and notes_dir or vim.fn.getcwd()

  builtin.find_files({
    prompt_title = "Insert Markdown Link",
    cwd = search_root,
    attach_mappings = function(prompt_bufnr)
      actions.select_default:replace(function()
        local entry = action_state.get_selected_entry()
        actions.close(prompt_bufnr)
        if not entry then return end

        local target = entry.path or (search_root .. "/" .. entry.value)
        local rel = relpath(target, buf_dir)
        local label = vim.fn.fnamemodify(target, ":t:r")
        local link = string.format("[%s](%s)", label, rel)

        local row, col = unpack(vim.api.nvim_win_get_cursor(0))
        local line = vim.api.nvim_get_current_line()
        vim.api.nvim_set_current_line(line:sub(1, col) .. link .. line:sub(col + 1))
        vim.api.nvim_win_set_cursor(0, { row, col + #link })
      end)
      return true
    end,
  })
end, { desc = "Insert markdown link to a fuzzy-picked file" })

vim.keymap.set("n", "<leader>ml", "<cmd>MdLink<cr>", { desc = "Insert markdown link (fuzzy)" })

-- Auto-sort completed todo items to the top of their sibling group on save

local function get_indent(line)
  return #line:match("^%s*")
end

local function is_checkbox(line)
  return line:match("^%s*[-*+]%s+%[[ x]%]") ~= nil
end

local function is_checked(line)
  return line:match("^%s*[-*+]%s+%[x%]") ~= nil
end

local function sort_todos(lines)
  local result = {}
  local i = 1

  while i <= #lines do
    local line = lines[i]
    if not is_checkbox(line) then
      table.insert(result, line)
      i = i + 1
    else
      local group_indent = get_indent(line)
      local blocks = {}

      while i <= #lines do
        local cur = lines[i]
        local cur_indent = get_indent(cur)

        if cur_indent < group_indent then break end
        if cur_indent == group_indent and not is_checkbox(cur) then break end
        if cur_indent > group_indent then
          blocks[#blocks].lines[#blocks[#blocks].lines + 1] = cur
          i = i + 1
        else
          local block = { lines = { cur }, checked = is_checked(cur) }
          table.insert(blocks, block)
          i = i + 1
        end
      end

      -- Add index to blocks for stable sort
      for idx, block in ipairs(blocks) do
        block.original_index = idx
        if #block.lines > 1 then
          local parent = block.lines[1]
          local children = {}
          for j = 2, #block.lines do children[j - 1] = block.lines[j] end
          local sorted_children = sort_todos(children)
          block.lines = { parent }
          for _, cl in ipairs(sorted_children) do
            table.insert(block.lines, cl)
          end
        end
      end

      -- Stable sort: completed items first, preserve original order for ties
      table.sort(blocks, function(a, b)
        local av = a.checked and 0 or 1
        local bv = b.checked and 0 or 1
        if av == bv then
          return a.original_index < b.original_index
        end
        return av < bv
      end)

      for _, block in ipairs(blocks) do
        for _, bl in ipairs(block.lines) do
          table.insert(result, bl)
        end
      end
    end
  end

  return result
end

vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = "*.md",
  callback = function()
    local filepath = vim.api.nvim_buf_get_name(0)
    if not filepath:find(notes_dir, 1, true) then return end

    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    local sorted = sort_todos(lines)

    local changed = false
    for idx, l in ipairs(sorted) do
      if l ~= lines[idx] then
        changed = true
        break
      end
    end
    if changed then
      vim.api.nvim_buf_set_lines(0, 0, -1, false, sorted)
    end
  end,
})

-- Create quick scratch note
vim.api.nvim_create_user_command("QuickNote", function()
  local date = os.date("%Y-%m-%d")
  local time = os.date("%H%M")
  local filename = string.format("%s_%s.md", date, time)
  local scratch_dir = vim.fn.fnamemodify("~/notes/notes/scratch", ":p")
  local target_file = scratch_dir .. filename

  -- Create scratch directory if it doesn't exist
  vim.fn.mkdir(scratch_dir, "p")

  -- Create empty file
  vim.fn.writefile({}, target_file)

  vim.notify("✓ Created quick note: " .. filename, vim.log.levels.INFO)

  -- Open the new file
  vim.cmd("edit " .. target_file)
end, { desc = "Create timestamped quick note in scratch" })
