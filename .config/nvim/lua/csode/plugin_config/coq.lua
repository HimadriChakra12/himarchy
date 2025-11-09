vim.g.coq_settings = {
	auto_start = "shut-up",
	keymap = {
		recommended = false, -- disable default keymaps so we can customize
		accept = "<space>", -- accept completion with Space
	},
	clients = {
		buffers = {
			enabled = true, -- ✅ Enable buffer word completion
		},
	},
}
vim.cmd("packadd coq_nvim")
vim.api.nvim_set_keymap("i", "<Space>", [[pumvisible() ? "\<C-y>" : " "]], { expr = true, noremap = true })
vim.api.nvim_set_keymap("i", "<CR>", [[pumvisible() ? "\<C-e>" : "\<CR>"]], { expr = true, noremap = true })

require("coq") -- this sets up coq globally
