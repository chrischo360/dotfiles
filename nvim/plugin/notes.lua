-- Custom commands for note-taking workflow
-- This file is auto-loaded by neovim from the plugin/ directory

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

vim.api.nvim_create_user_command("NewMeeting", function(opts)
  local meeting_name = opts.args

  if not meeting_name or meeting_name == "" then
    vim.notify("Error: Please provide meeting name (e.g., :NewMeeting mike-1on1)", vim.log.levels.ERROR)
    return
  end

  local date = os.date("%Y-%m-%d")
  local filename = string.format("%s_%s.md", date, meeting_name)
  local meetings_dir = vim.fn.fnamemodify("~/notes/meetings", ":p")
  local target_file = meetings_dir .. filename

  -- Create meetings directory if it doesn't exist
  vim.fn.mkdir(meetings_dir, "p")

  -- Check if file already exists
  if vim.fn.filereadable(target_file) == 1 then
    vim.notify("Error: Meeting note already exists: " .. filename, vim.log.levels.WARN)
    return
  end

  -- Create empty file
  vim.fn.writefile({}, target_file)

  vim.notify("✓ Created meeting note: " .. filename, vim.log.levels.INFO)

  -- Open the new file
  vim.cmd("edit " .. target_file)
end, { nargs = 1, desc = "Create new meeting note with date" })

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
