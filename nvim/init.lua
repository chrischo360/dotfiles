require("config.lazy")

-- Git performance profiling command
vim.api.nvim_create_user_command("ProfileGit", function()
  require("utils.profile-git").show_profile()
end, { desc = "Profile git and diffview performance" })
