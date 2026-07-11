-- Plugin: Persisted.nvim
-- Description: Automatic session management. Saves and restores your workspace (open files, window layout) when you quit and restart nvim.
--              Sessions are saved per git branch/directory.

return {
  "olimorris/persisted.nvim",
  lazy = false, -- Load immediately
  priority = 1000, -- Load early
  config = function()
    require("persisted").setup({
      autostart = true, -- Automatically start the plugin on load
      autoload = true, -- Automatically load the session for the cwd on Neovim startup
      autosave = true, -- Automatically save the session on exit
      follow_cwd = true, -- Change the session file to match any change in the cwd

      -- Function to determine if a session should be saved
      should_save = function()
        -- Only save if we have real buffers open (not just empty or help buffers)
        if vim.fn.argc() > 0 then
          return true -- Always save if files were passed as arguments
        end

        local bufs = vim.api.nvim_list_bufs()
        for _, buf in ipairs(bufs) do
          if vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].buflisted then
            local buftype = vim.bo[buf].buftype
            local bufname = vim.api.nvim_buf_get_name(buf)

            -- Filter out special buffers
            if buftype == "" and bufname ~= "" and not bufname:match("^term://") and not bufname:match("^oil://") then
              return true -- Found a real file buffer
            end
          end
        end
        return false
      end,

      save_dir = vim.fn.expand(vim.fn.stdpath("data") .. "/sessions/"), -- Directory where session files are saved
      use_git_branch = true, -- Include git branch in session file name (matches buffer tracking)

      -- Function to run when `autoload = true` but there is no session to load
      on_autoload_no_session = function()
        vim.notify("No session found for " .. vim.fn.getcwd(), vim.log.levels.WARN)
      end,

      -- Pre-save hook to clean up before saving
      pre_save = function()
        -- Close any floating windows
        for _, win in ipairs(vim.api.nvim_list_wins()) do
          if vim.api.nvim_win_get_config(win).relative ~= "" then
            pcall(vim.api.nvim_win_close, win, false)
          end
        end
      end,

      -- Post-save notification
      post_save = function()
        vim.notify("Session saved!", vim.log.levels.INFO)
      end,

      -- Post-load notification
      post_load = function()
        vim.notify("Session loaded!", vim.log.levels.INFO)
      end,

      allowed_dirs = {
        vim.fn.expand("~/codebase"),
        vim.fn.expand("~/dotfiles"),
      }, -- Table of dirs that the plugin will start and autoload from
      ignored_dirs = {
        vim.fn.expand("~/leetcode"),
      }, -- Table of dirs that are ignored for starting and autoloading

      telescope = {
        mappings = { -- Mappings for managing sessions in Telescope
          copy_session = "<C-c>",
          change_branch = "<C-b>",
          delete_session = "<C-d>",
        },
        icons = { -- icons displayed in the Telescope picker
          selected = " ",
          dir = "  ",
          branch = " ",
        },
      },
    })

    -- Periodically save the session as a safety net against unclean exits
    -- (crashes, OS restarts, `kill -9`, closing the terminal, etc. skip
    -- VimLeavePre, which is the only event persisted.nvim saves on by default)
    --
    -- Guard: persisted.nvim names session files by cwd+branch, so if you have
    -- multiple Neovim instances open in the same directory/branch, periodic
    -- saves from one would silently clobber another's layout. To avoid that,
    -- only one instance per session file ("the owner") does periodic saves;
    -- the others fall back to the original save-on-exit-only behaviour.
    local is_session_owner = false

    local function lock_path()
      return require("persisted").current() .. ".lock"
    end

    local function is_pid_alive(pid)
      if not pid then
        return false
      end
      local ok, result = pcall(vim.uv.kill, pid, 0)
      return ok and result == 0
    end

    local function release_lock()
      if not is_session_owner then
        return
      end
      local path = lock_path()
      local f = io.open(path, "r")
      if f then
        local pid = tonumber(f:read("*a"))
        f:close()
        if pid == vim.fn.getpid() then
          vim.fn.delete(path)
        end
      end
      is_session_owner = false
    end

    local function acquire_lock()
      release_lock() -- give up ownership of any previous session (e.g. after DirChanged)

      local path = lock_path()
      local existing = io.open(path, "r")
      if existing then
        local pid = tonumber(existing:read("*a"))
        existing:close()
        if is_pid_alive(pid) and pid ~= vim.fn.getpid() then
          is_session_owner = false -- another live instance already owns this session
          return
        end
      end

      local f = io.open(path, "w")
      if f then
        f:write(tostring(vim.fn.getpid()))
        f:close()
      end
      is_session_owner = true
    end

    acquire_lock()
    vim.api.nvim_create_autocmd("DirChanged", { callback = acquire_lock })
    vim.api.nvim_create_autocmd("VimLeavePre", { callback = release_lock })

    local persisted_timer = vim.uv.new_timer()
    persisted_timer:start(60000, 60000, vim.schedule_wrap(function()
      if vim.g.persisting and is_session_owner then
        require("persisted").save()
      end
    end))

    -- Also save on focus lost / buffer write, since those are natural checkpoints
    vim.api.nvim_create_autocmd({ "FocusLost", "BufWritePost" }, {
      callback = function()
        if vim.g.persisting and is_session_owner then
          require("persisted").save()
        end
      end,
    })
  end,
  keys = {
    {
      "<leader>ql",
      function()
        require("persisted").load()
      end,
      desc = "Load session",
    },
    {
      "<leader>qs",
      function()
        require("persisted").save()
      end,
      desc = "Save session",
    },
    {
      "<leader>qd",
      function()
        require("persisted").stop()
      end,
      desc = "Stop session",
    },
    {
      "<leader>qr",
      function()
        require("persisted").delete()
      end,
      desc = "Delete session",
    },
    {
      "<leader>qt",
      function()
        require("persisted").toggle()
      end,
      desc = "Toggle session",
    },
    { "<leader>qf", "<cmd>Telescope persisted<cr>", desc = "Find sessions" },
    {
      "<leader>qc",
      function()
        local sessions_dir = vim.fn.stdpath("data") .. "/sessions/"
        local sessions = vim.fn.glob(sessions_dir .. "*.vim", true, true)
        if #sessions > 0 then
          local choice = vim.fn.confirm("Delete all " .. #sessions .. " sessions?", "&Yes\n&No", 2)
          if choice == 1 then
            for _, session in ipairs(sessions) do
              vim.fn.delete(session)
            end
            vim.notify("Deleted " .. #sessions .. " sessions!", vim.log.levels.INFO)
          end
        else
          vim.notify("No sessions to delete", vim.log.levels.INFO)
        end
      end,
      desc = "Clear all sessions",
    },
    {
      "<leader>qi",
      function()
        local persisted = require("persisted")
        print("Session started:", persisted.session_started)
        print("Current session:", persisted.current_session or "None")
        print("Save dir:", vim.fn.stdpath("data") .. "/sessions/")
      end,
      desc = "Session info",
    },
    {
      "<leader>qb",
      function()
        print("=== Current Buffer Analysis ===")
        local bufs = vim.api.nvim_list_bufs()
        for _, buf in ipairs(bufs) do
          if vim.api.nvim_buf_is_loaded(buf) then
            local bufname = vim.api.nvim_buf_get_name(buf)
            local buftype = vim.bo[buf].buftype
            local filetype = vim.bo[buf].filetype
            local listed = vim.bo[buf].buflisted

            -- Check if this would be filtered
            local is_special = buftype ~= ""

            local status = is_special and "🚫 FILTERED" or "✅ INCLUDED"
            print(
              string.format(
                "Buffer %d: %s [%s] (%s/%s) %s",
                buf,
                bufname == "" and "<unnamed>" or bufname,
                filetype,
                buftype,
                listed and "listed" or "unlisted",
                status
              )
            )
          end
        end
      end,
      desc = "Debug buffer state",
    },
  },
}
