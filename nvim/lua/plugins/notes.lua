-- Custom commands for note-taking workflow

return {
  {
    "folke/lazy.nvim",
    lazy = false,
    config = function()
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
    end,
  },
}
