require('rho')
require('dx')


-- Line Numbers
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.fillchars = { eob = " " }

-- Better searching
vim.opt.incsearch = true
vim.opt.hlsearch = true
vim.opt.ignorecase = true
vim.opt.smartcase = true  -- Makes search case-sensitive if uppercase letters are used


-- Faster Keypress
vim.opt.updatetime = 300
vim.opt.timeoutlen = 500

-- Tabs and Indent
vim.opt.expandtab = true  -- Convert tabs to spaces
vim.opt.tabstop = 4       -- Number of spaces a tab counts for
vim.opt.shiftwidth = 4    -- Number of spaces for autoindent
vim.opt.softtabstop = 4
vim.opt.autoindent = true
vim.opt.smartindent = true

-- No Annoy
vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.writebackup = false

-- Yanked Text
vim.cmd [[
  augroup YankHighlight
    autocmd!
    autocmd TextYankPost * silent! lua vim.highlight.on_yank { higroup="IncSearch", timeout=200 }
  augroup END
]]

-- TP BG
-- vim.cmd([[highlight Normal guibg=NONE ctermbg=NONE]])
-- vim.cmd([[highlight NonText guibg=NONE ctermbg=NONE]])
-- vim.cmd([[highlight NormalNC guibg=NONE ctermbg=NONE]])
-- vim.cmd([[highlight EndOfBuffer guibg=NONE ctermbg=NONE]])

vim.opt.termguicolors = true  -- Enable 24-bit colors
vim.opt.background = "dark"   -- Set to dark mode
vim.cmd("colorscheme gruvbox")

vim.keymap.set("n", "<leader>pm", function()
    require("pacman.maze").open()
end, { desc = "Plugin Manager GUI" })

vim.keymap.set("n", "<leader>e", function()
    require("netwr").open()
end, { desc = "Plugin Manager GUI" })
local sqlite_preview = require("sql")

vim.api.nvim_create_autocmd("BufWritePost", {
  pattern = "*.sql",
  callback = function()
    sqlite_preview.preview()
  end,
})
