require("config.lazy")

-- Mode-specific cursor shapes for better visual feedback
vim.opt.guicursor = {
  "n-v-c:block",           -- Normal, Visual, Command: block cursor
  "i-ci-ve:ver25",         -- Insert, Command Insert, Visual-Replace: thin vertical bar
  "r-cr:hor20",            -- Replace, Command Replace: horizontal bar
  "o:hor50",               -- Operator-pending: thick horizontal bar
  "a:blinkwait700-blinkoff400-blinkon250",  -- All modes: controlled blinking
  "sm:block-blinkwait175-blinkoff150-blinkon175",  -- Showmatch: fast blinking block
}

-- Git performance profiling command
vim.api.nvim_create_user_command("ProfileGit", function()
  require("utils.profile-git").show_profile()
end, { desc = "Profile git and diffview performance" })
