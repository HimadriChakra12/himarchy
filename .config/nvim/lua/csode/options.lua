vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.smartindent = true
vim.opt.backup = false
vim.opt.undofile = true

vim.opt.hlsearch = false
vim.opt.incsearch = true

vim.opt.termguicolors = true
vim.opt.scrolloff = 100
vim.opt.signcolumn = "yes"
vim.opt.isfname:append("@-@")
vim.opt.updatetime = 50

vim.opt.showmode = false
vim.opt.showcmd = false

vim.opt.linebreak = true
vim.opt.breakindent = true
-- vim.api.nvim_create_autocmd("VimEnter", {
-- 	callback = function()
-- 		vim.cmd("COQnow")
-- 	end,
-- })
