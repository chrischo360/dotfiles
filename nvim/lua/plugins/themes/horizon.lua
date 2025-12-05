-- Theme: Horizon
-- Description: Beautifully warm dual theme with a gradient background.
-- Variants: horizon (dark only)

return {
  "akinsho/horizon.nvim",
  lazy = true,
  priority = 1000,
  config = function()
    require('horizon').setup()
  end,
}
