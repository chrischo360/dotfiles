local function diff_utils()
  return require("utils.diff-utils")
end

local function load_diffview()
  pcall(function()
    require("lazy").load({ plugins = { "diffview.nvim" } })
  end)
end

vim.keymap.set("n", "<leader>gy", function()
  diff_utils().copy_github_permalink()
end, { noremap = true, silent = true, desc = "Copy GitHub permalink" })

vim.keymap.set("v", "<leader>gy", function()
  diff_utils().copy_github_permalink_range()
end, { noremap = true, silent = true, desc = "Copy GitHub permalink (selection)" })

vim.keymap.set("n", "<leader>go", function()
  diff_utils().open_on_github()
end, { noremap = true, silent = true, desc = "Open file on GitHub" })

vim.keymap.set("n", "<leader>gp", function()
  diff_utils().open_pr_diff()
end, { noremap = true, silent = true, desc = "Open GitHub PR in diffview" })

vim.keymap.set("n", "<leader>dv", function()
  load_diffview()
  if next(require("diffview.lib").views) == nil then
    vim.cmd("DiffviewOpen")
  else
    vim.cmd("DiffviewClose")
  end
end, { desc = "Toggle Diffview (uncommitted changes)" })

vim.keymap.set("n", "<leader>dfh", "<cmd>DiffviewFileHistory %<cr>", { desc = "File History (current file)" })
vim.keymap.set("n", "<leader>dfa", "<cmd>DiffviewFileHistory<cr>", { desc = "File History (all files)" })
vim.keymap.set("v", "<leader>gl", ":'<,'>DiffviewFileHistory<CR>", { desc = "Git Line History (selected lines)" })

for i = 1, 10 do
  local lhs = i == 10 and "<leader>d0" or ("<leader>d" .. i)
  vim.keymap.set("n", lhs, "<cmd>DiffviewOpen HEAD~" .. i .. "<cr>", { desc = "Diff with HEAD~" .. i })
end

vim.keymap.set("n", "<leader>dm", function()
  diff_utils().compare_with_main()
end, { desc = "Compare with main/master" })

vim.keymap.set("n", "<leader>db", function()
  diff_utils().compare_with_branch_interactive()
end, { desc = "Compare current with branch" })

vim.keymap.set("n", "<leader>d2b", function()
  diff_utils().compare_branches_interactive()
end, { desc = "Compare two branches" })

vim.keymap.set("n", "<leader>dq", function()
  diff_utils().quick_diff_menu()
end, { desc = "Quick Diff Menu" })
