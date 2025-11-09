local M = {}

function M.list_todos()
	local todos = {}
	local bufnr = vim.api.nvim_get_current_buf()
	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

	for i, line in ipairs(lines) do
		if line:match("%s*TODO") then
			table.insert(todos, {
				bufnr = bufnr,
				lnum = i,
				col = 1,
				text = line,
			})
		end
	end

	if #todos == 0 then
		vim.notify("No TODOs found in current buffer", vim.log.levels.INFO)
		return
	end

	vim.fn.setqflist({}, " ", {
		title = "TODOs in current buffer",
		items = todos,
	})
	vim.cmd("copen")
end

vim.api.nvim_create_user_command("TodoList", function()
	M.list_todos()
end, {
	desc = "Show TODOs in the current buffer using quickfix list",
})

return M
