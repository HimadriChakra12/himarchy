local todo = require("todo-comments")
todo.setup({
	highlight = {
		-- Highlight even if the keyword is not in a comment
		pattern = [[.*<(KEYWORDS)\s*:]], -- highlight `.
		comments_only = false,
	},
	search = {
		pattern = [[\b(KEYWORDS)\b]],
	},
})
