-- Simple local plugin example
local M = {}

M.config = {
	message = "LETS FUCKING GO"
}

function M.setup(opts)
	M.config = vim.tbl_deep_extend("force", M.config, opts or {})

	vim.keymap.set('n', '<leader>lfg', function()
		vim.notify(M.config.message, vim.log.levels.INFO)
	end, { desc = 'LETS FUCKING GO' })
end

function M.greet()
	vim.notify(M.config.message, vim.log.levels.INFO)
end

return M
