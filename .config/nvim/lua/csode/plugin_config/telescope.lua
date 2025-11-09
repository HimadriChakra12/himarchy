local telescope = require('telescope')

telescope.setup({
  defaults = {
    sorting_strategy = "ascending",
    layout_config = { prompt_position = "top" },
  },
  extensions = {
    fzf = {
      fuzzy = true,
      override_generic_sorter = true,
      override_file_sorter = true,
      case_mode = "smart_case",
    },
  },
})

telescope.load_extension('fzf')

local builtin = require('telescope.builtin')

vim.keymap.set('n', '<leader>pf', builtin.find_files, {})
vim.keymap.set('n', '<C-p>', builtin.git_files, {})
vim.keymap.set('n', '<leader>pws', function()
  builtin.grep_string({ search = vim.fn.expand("<cword>") })
end)
vim.keymap.set('n', '<leader>pWs', function()
  builtin.grep_string({ search = vim.fn.expand("<cWORD>") })
end)
vim.keymap.set('n', '<leader>ps', function()
  builtin.grep_string({ search = vim.fn.input("Grep > ") })
end)
vim.keymap.set('n', '<leader>vh', builtin.help_tags, {})

vim.keymap.set('n', '<leader>fg', builtin.git_files, { noremap = true, silent = true })

