--pin_buf Quality-of-Life Keybindings
vim.g.mapleader = " "  -- Set leader key to Space

local keymap = vim.api.nvim_set_keymap
local opts = { noremap = true, silent = true }

-- Better window movement
keymap("n", "<C-h>", "<C-w>h", opts)
keymap("n", "<C-j>", "<C-w>j", opts)
keymap("n", "<C-k>", "<C-w>k", opts)
keymap("n", "<C-l>", "<C-w>l", opts)

keymap("n", "<leader>w", ":bd<CR>", opts)
keymap("n", "<leader>q", ":q!<CR>", opts)

-- Fast saving & quitting
-- keymap("n", "<Leader>w", ":w<CR>", opts)
-- keymap("n", "<Leader>qq", ":q!<CR>", opts)
keymap("n", "<Leader>x", ":x<CR>", opts)

-- For Lua (init.lua)
vim.keymap.set('n', '<leader>e', '<cmd>Exp<CR>', { noremap = true, silent = true })
vim.keymap.set('n', '<leader>cc', '<cmd>CompileMode<CR>', { noremap = true, silent = true })
-- vim.keymap.set('n', '<leader>e', '<cmd>Explorer<cr>')
vim.keymap.set('n', '<leader>n', ':enew<CR>', { noremap = true, silent = true })
vim.keymap.set("n", "<leader>h", ":nohlsearch<CR>", { noremap = true, silent = true })

-- vim.api.nvim_set_keymap("n", "<leader>ff", ":FF<CR>", { noremap = true, silent = true })
vim.keymap.set('n', '<leader>o', ':Telescope find_files<CR>', { noremap = true, silent = true })
vim.keymap.set('n', '<leader>fg', ':Telescope live_grep<CR>', { noremap = true, silent = true })
--vim.keymap.set('n', '<leader><leader>', require('telescope.builtin').buffers, { noremap = true, silent = true })   

vim.keymap.set("n", "z", ":Zcd ", { noremap = true})
vim.keymap.set("n", "<leader>.", ":Zt<CR>", { noremap = true, silent = true })
-- Option 1: Mapping to Clear Highlighting (e.g., <CR> after search)
vim.api.nvim_set_keymap('n', '<CR>', ':noh<CR>', { noremap = true, silent = true })

vim.api.nvim_set_keymap('n', '<leader>z', ':ZenMode<CR>', { noremap = true, silent = true })


-- Option 3: Mapping to a Custom Key (e.g., <Leader>h)
vim.api.nvim_set_keymap('n', '<Leader>h', ':noh<CR>', { noremap = true, silent = true })

-- Option 4: Using an Autocommand
vim.api.nvim_create_autocmd("CmdlineLeave", {
  pattern = "*",
  command = "noh",
})
vim.api.nvim_set_keymap('n', '<Leader>gfo', ':noh<CR>', { noremap = true, silent = true })
-- Keybindings configuration
vim.keymap.set('n', '<leader><CR>', ':TerminalPopup<CR>', {silent = true, desc = 'Toggle Terminal Popup' })
-- vim.keymap.set('n', '<leader><leader>', ':BufferManager<CR>', {silent = true, desc = 'Toggle Buffer Manager Popup' })

vim.keymap.set('n', '<leader>Y', '"+y', {silent = true, desc = 'Toggle Terminal Popup' })

vim.keymap.set("n", "<leader>fp", function()
  require("pacman.bricks").find_plugin()
end, { desc = "Find and Add Plugin" })

local pin_buf = require("plugins.bufman")

-- Toggle pin for current buffer
vim.keymap.set("n", "<leader>bp", pin_buf.toggle_pin, { desc = "Pin buffer" })

-- Open pinned + normal buffer list (pinned first)
vim.keymap.set("n", "<leader><leader>", pin_buf.buffers_with_pins, { desc = "Find buffers (pinned first)" })
