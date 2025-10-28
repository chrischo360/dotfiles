return {
  'nvim-lualine/lualine.nvim',
  dependencies = { 'nvim-tree/nvim-web-devicons' },
  config = function()
    require('lualine').setup({
      options = {
        theme = 'modus-vivendi',
        component_separators = { left = '', right = ''},
        section_separators = { left = '', right = ''},
        globalstatus = true,
      },
      sections = {
        lualine_a = { 'mode' },
        lualine_b = {
          'branch',
          {'diff', symbols = { added = ' ', modified = ' ', removed = ' ' }},
          'diagnostics'
        },
        lualine_c = {
          { 'filename', path = 1, symbols = { modified = '●', readonly = '', unnamed = '[No Name]' } },
          'searchcount',
          {
            -- Git blame for current line
            function()
              if vim.b.gitsigns_blame_line then
                local blame = vim.b.gitsigns_blame_line
                -- Truncate to show just author and relative time
                local author = blame:match('^([^,]+)')
                local time = blame:match('%((.-)%)%s*$')
                if author and time then
                  return ' ' .. author .. ' • ' .. time
                end
                return ' ' .. blame
              end
              return ''
            end,
            color = { fg = '#727169', gui = 'italic' },
            cond = function() return vim.b.gitsigns_blame_line ~= nil end
          }
        },
        lualine_x = {
          {
            -- LSP server status
            function()
              local clients = vim.lsp.get_active_clients({ bufnr = 0 })
              if #clients == 0 then return '' end
              local names = {}
              for _, client in ipairs(clients) do
                table.insert(names, client.name)
              end
              return ' ' .. table.concat(names, '|')
            end,
            color = { fg = '#7e9cd8' }
          },
          'encoding',
          { 'fileformat', symbols = { unix = 'LF', dos = 'CRLF', mac = 'CR' } },
          'filetype'
        },
        lualine_y = { 'progress' },
        lualine_z = { 'location' }
      }
    })
  end
}
