return {
	'sindrets/diffview.nvim',
	cmd = { 'DiffviewOpen', 'DiffviewClose', 'DiffviewToggle', 'DiffviewFileHistory' },
	keys = {
		{
			'<leader>dv',
			function()
				if next(require('diffview.lib').views) == nil then
					vim.cmd('DiffviewOpen')
				else
					vim.cmd('DiffviewClose')
				end
			end,
			desc = 'Toggle Diffview window',
		},
	},
}
