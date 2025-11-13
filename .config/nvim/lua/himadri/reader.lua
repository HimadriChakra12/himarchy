local reader_mode = false

function ToggleReaderMode()
  if not reader_mode then
    -- Save current UI state
    vim.g._last_showmode = vim.o.showmode
    vim.g._last_ruler = vim.o.ruler
    vim.g._last_showcmd = vim.o.showcmd
    vim.g._last_laststatus = vim.o.laststatus
    vim.g._last_cmdheight = vim.o.cmdheight
    vim.g._last_signcolumn = vim.o.signcolumn
    vim.g._last_number = vim.wo.number
    vim.g._last_relativenumber = vim.wo.relativenumber
    vim.g._last_showtabline = vim.o.showtabline

    -- Turn off distractions
    vim.o.showmode = false
    vim.o.ruler = false
    vim.o.showcmd = false
    vim.o.laststatus = 0
    vim.o.cmdheight = 1 -- keep command line visible
    vim.o.signcolumn = "no"
    vim.wo.number = false
    vim.wo.relativenumber = false
    vim.o.showtabline = 0
    vim.o.cursorline = false
    vim.o.cursorcolumn = false

    reader_mode = true
  else
    -- Restore settings
    vim.o.showmode = vim.g._last_showmode
    vim.o.ruler = vim.g._last_ruler
    vim.o.showcmd = vim.g._last_showcmd
    vim.o.laststatus = vim.g._last_laststatus
    vim.o.cmdheight = vim.g._last_cmdheight
    vim.o.signcolumn = vim.g._last_signcolumn
    vim.wo.number = vim.g._last_number
    vim.wo.relativenumber = vim.g._last_relativenumber
    vim.o.showtabline = vim.g._last_showtabline
    vim.o.cursorline = true
    vim.o.cursorcolumn = true

    reader_mode = false
  end
end

vim.api.nvim_set_keymap("n", "<leader>r", ":lua ToggleReaderMode()<CR>", { noremap = true, silent = true })
