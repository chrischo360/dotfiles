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
    },
  },
  keys = {
    { "<leader>ji", "<cmd>Jira info<cr>", desc = "JIRA issue info" },
    { "<leader>jb", "<cmd>Jira PGL<cr>", desc = "JIRA PGL board" },
  },
}
