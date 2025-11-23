-- Plugin: Git Conflict Resolution
-- Description: Better merge conflict resolution with visual indicators and quick resolution commands
-- Keybindings: co (choose ours), ct (choose theirs), cb (both), c0 (none), ]x/[x (next/prev conflict)

return {
  'akinsho/git-conflict.nvim',
  version = "*",
  event = "BufReadPre",
  config = function()
    require('git-conflict').setup({
      default_mappings = true,
      default_commands = true,
      disable_diagnostics = true,
      list_opener = 'copen',
      highlights = {
        incoming = 'DiffAdd',
        current = 'DiffText',
      }
    })
  end
}
