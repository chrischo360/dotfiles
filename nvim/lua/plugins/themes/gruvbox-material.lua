return {
  "sainnhe/gruvbox-material",
  lazy = true,
  config = function()
    -- Available options: 'hard', 'medium', 'soft'
    vim.g.gruvbox_material_background = 'medium'

    -- Available options: 'material', 'mix', 'original'
    vim.g.gruvbox_material_foreground = 'material'

    -- Enable bold
    vim.g.gruvbox_material_enable_bold = 1

    -- Enable italic
    vim.g.gruvbox_material_enable_italic = 1

    -- Better performance
    vim.g.gruvbox_material_better_performance = 1
  end,
}
