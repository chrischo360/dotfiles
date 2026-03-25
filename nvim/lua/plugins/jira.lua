local function get_jira_prs(ticket)
  -- Show loading notification
  vim.notify("Searching for PRs for " .. ticket .. "...", vim.log.levels.INFO)

  -- Use gh CLI to search for PRs mentioning this ticket in Wayfair orgs
  local search_cmd = string.format(
    'gh search prs "%s" --owner wayfair-shared --owner wayfair-secure --json number,title,url,state,author --limit 50',
    ticket
  )

  vim.fn.jobstart(search_cmd, {
    stdout_buffered = true,
    on_stdout = function(_, data)
      if not data or #data == 0 then
        vim.notify("No PRs found for " .. ticket, vim.log.levels.INFO)
        return
      end

      -- Filter out empty strings before concatenating
      local filtered = vim.tbl_filter(function(line)
        return line ~= ""
      end, data)
      local json_str = table.concat(filtered, "\n")

      local ok, prs = pcall(vim.json.decode, json_str)
      if not ok or not prs or #prs == 0 then
        vim.notify("No PRs found for " .. ticket, vim.log.levels.INFO)
        return
      end

      -- Display PRs in a popup
      local lines = { "Pull Requests for " .. ticket, "" }
      for i, pr in ipairs(prs) do
        local state_lower = pr.state:lower()
        local state_icon = state_lower == "open" and "🟢" or state_lower == "merged" and "🟣" or "🔴"
        table.insert(lines, string.format("%s [%s] %s @%s", state_icon, pr.state, pr.title, pr.author.login))
        table.insert(lines, pr.url)
        table.insert(lines, "")
      end

      -- Create a floating window
      local buf = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
      vim.api.nvim_buf_set_option(buf, "modifiable", false)
      vim.api.nvim_buf_set_option(buf, "buftype", "nofile")

      local width = 100
      local height = math.min(#lines + 2, 30)
      local win = vim.api.nvim_open_win(buf, true, {
        relative = "editor",
        width = width,
        height = height,
        row = math.floor((vim.o.lines - height) / 2),
        col = math.floor((vim.o.columns - width) / 2),
        style = "minimal",
        border = "rounded",
        title = " Pull Requests ",
        title_pos = "center",
      })

      -- Enable line numbers in the floating window
      vim.api.nvim_win_set_option(win, "number", true)
      vim.api.nvim_win_set_option(win, "relativenumber", true)

      -- Close on q or Esc
      vim.api.nvim_buf_set_keymap(buf, "n", "q", ":close<CR>", { noremap = true, silent = true })
      vim.api.nvim_buf_set_keymap(buf, "n", "<Esc>", ":close<CR>", { noremap = true, silent = true })

      -- Open URL on current line with gx
      vim.api.nvim_buf_set_keymap(buf, "n", "gx", "", {
        noremap = true,
        silent = true,
        callback = function()
          local line = vim.api.nvim_get_current_line()
          local url = line:match("https?://[%w-._~:/?#%[%]@!$&'()*+,;=%%]+")
          if url then
            vim.ui.open(url)
          else
            vim.notify("No URL found on current line", vim.log.levels.WARN)
          end
        end,
      })
    end,
    on_stderr = function(_, data)
      if data and #data > 0 then
        local filtered = vim.tbl_filter(function(line)
          return line ~= ""
        end, data)
        if #filtered > 0 then
          vim.notify("gh error: " .. table.concat(filtered, "\n"), vim.log.levels.ERROR)
        end
      end
    end,
  })
end

return {
  "letieu/jira.nvim",
  dependencies = { "nvim-lua/plenary.nvim" },
  event = "VeryLazy",
  opts = {
    jira = {
      limit = 200,
      api_version = "2",
    },
    queries = {
      ["My Tasks"] = "assignee = currentUser() AND statusCategory != Done ORDER BY updated DESC",
      ["Recent"] = "assignee = currentUser() ORDER BY updated DESC",
      ["PGL Active Sprint"] = "project = PGL AND sprint in openSprints() ORDER BY updated DESC",
      ["PGL My Tasks"] = "project = PGL AND assignee = currentUser() AND statusCategory != Done ORDER BY updated DESC",
      ["PGL My Sprint"] = "project = PGL AND assignee = currentUser() AND sprint in openSprints() ORDER BY updated DESC",
    },
  },
  keys = {
    { "<leader>ji", "<cmd>Jira info<cr>", desc = "JIRA issue info" },
    {
      "<leader>jb",
      function()
        vim.cmd("Jira PGL")
        vim.defer_fn(function()
          local board = require("jira.board")
          board.switch_query("PGL My Sprint")
        end, 500)
      end,
      desc = "JIRA PGL my sprint",
    },
    {
      "K",
      function()
        -- Extract ticket number under cursor (e.g., PGL-905)
        local word = vim.fn.expand("<cWORD>")
        local ticket = word:match("([A-Z]+%-[0-9]+)")
        if ticket then
          -- Try to open Jira info, fallback to LSP hover on error
          local ok = pcall(vim.cmd, "Jira info " .. ticket)
          if not ok then
            vim.notify("Failed to load ticket " .. ticket, vim.log.levels.WARN)
            vim.lsp.buf.hover()
          end
        else
          -- Fallback to default K behavior (LSP hover)
          vim.lsp.buf.hover()
        end
      end,
      desc = "JIRA info or LSP hover",
      mode = "n",
    },
    {
      "<leader>gd",
      function()
        -- Extract ticket number under cursor (e.g., PGL-905)
        local word = vim.fn.expand("<cWORD>")
        local ticket = word:match("([A-Z]+%-[0-9]+)")
        if ticket then
          get_jira_prs(ticket)
        else
          vim.notify("No JIRA ticket found under cursor", vim.log.levels.WARN)
        end
      end,
      desc = "Show JIRA pull requests",
      mode = "n",
    },
  },
}
