-- ~/.config/nvim/lua/todo.lua
local M = {}

-- Open a .todo file in a floating popup
function M.open_popup(filepath)
  filepath = vim.fn.expand(filepath or "%:p")  -- normalize path

  -- Read file contents
  local lines = {}
  if vim.fn.filereadable(filepath) == 1 then
    lines = vim.fn.readfile(filepath)
  end

  -- Window dimensions
  local width = math.floor(vim.o.columns * 0.5)
  local height = math.floor(vim.o.lines * 0.5)
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)

  -- Create a buffer (not listed, but writable)
  local buf = vim.api.nvim_create_buf(true, false)
  vim.api.nvim_buf_set_name(buf, filepath)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(buf, "filetype", "todo")
  vim.api.nvim_buf_set_option(buf, "bufhidden", "hide")
  vim.api.nvim_buf_set_option(buf, "modifiable", true)
  vim.api.nvim_buf_set_option(buf, "readonly", false)

  -- Create floating window
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    style = "minimal",
    border = "rounded",
  })

  -- Set window-local options
  vim.wo[win].wrap = true
  vim.wo[win].number = true

  -- Setup folds, syntax, and keymaps
  M.setup_folds()
  M.setup_syntax()
  M.setup_keymaps()

  -- Save on write command
  vim.api.nvim_buf_create_user_command(buf, "TodoWrite", function()
    local new_lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    local ok, err = pcall(vim.fn.writefile, new_lines, filepath)
    if ok then
      vim.notify("Saved to " .. filepath, vim.log.levels.INFO)
    else
      vim.notify("Error saving: " .. err, vim.log.levels.ERROR)
    end
  end, {})

  -- Keymap: <leader>w to save
  vim.keymap.set("n", "<leader>w", ":TodoWrite<CR>", { buffer = buf, noremap = true, silent = true })
end

-- --------------------------
-- Syntax highlighting
-- --------------------------
function M.setup_syntax()
  vim.cmd [[
    " TODO / DONE
    syntax match TodoTask "^* TODO .*"
    syntax match DoneTask "^* DONE .*"
    highlight link TodoTask Keyword
    highlight link DoneTask Comment

    " DEADLINE, TAGS, PRIORITY
    syntax match TodoDeadline "^\s*DEADLINE:.*"
    syntax match TodoTags "^\s*TAGS:.*"
    syntax match TodoPriority "^\s*PRIORITY:.*"
    highlight TodoDeadline guifg=#ff5555 ctermfg=Red
    highlight TodoTags guifg=#f1fa8c ctermfg=Yellow
    highlight TodoPriority guifg=#ff79c6 ctermfg=Magenta

    " Folded lines
    highlight Folded guifg=#6272a4 gui=italic ctermfg=DarkBlue
  ]]
end

-- --------------------------
-- Toggle TODO/DONE (any heading level)
-- --------------------------
function M.toggle()
  local line = vim.api.nvim_get_current_line()
  if line:match("^%*+ TODO") then
    local new_line = line:gsub("^%*+ TODO", function(s) return s:gsub("TODO","DONE") end)
    vim.api.nvim_set_current_line(new_line)
  elseif line:match("^%*+ DONE") then
    local new_line = line:gsub("^%*+ DONE", function(s) return s:gsub("DONE","TODO") end)
    vim.api.nvim_set_current_line(new_line)
  end
end

-- --------------------------
-- Jump to next/previous task
-- --------------------------
function M.next_task()
  local lnum = vim.fn.search("^* ", "W")
  if lnum > 0 then vim.api.nvim_win_set_cursor(0, {lnum, 0}) end
end

function M.prev_task()
  local lnum = vim.fn.search("^* ", "bW")
  if lnum > 0 then vim.api.nvim_win_set_cursor(0, {lnum, 0}) end
end

-- --------------------------
-- Insert new task
-- --------------------------
function M.new_task()
  local row = vim.api.nvim_win_get_cursor(0)[1]
  local line = vim.api.nvim_get_current_line()
  local level = line:match("^(%*+)") or "*"
  local new_line = level .. " TODO "
  vim.api.nvim_buf_set_lines(0, row, row, true, { new_line })
  vim.api.nvim_win_set_cursor(0, {row+1, #new_line})
end

-- --------------------------
-- Folding setup
-- --------------------------
function M.setup_folds()
  vim.wo.foldmethod = "expr"
  vim.wo.foldexpr = "v:lua.todo_foldexpr(v:lnum)"
  vim.wo.foldlevel = 99
end

-- Fold expression function with DONE auto-fold
function _G.todo_foldexpr(lnum)
  local line = vim.fn.getline(lnum)
  local stars = line:match("^(%*+)")
  if stars then
    if line:match("^%*+ DONE") then
      -- Fold DONE tasks automatically
      vim.cmd(lnum .. "fold") 
    end
    return #stars
  else
    return 0
  end
end

-- --------------------------
-- Keymaps
-- --------------------------
function M.setup_keymaps()
  local opts = { noremap = true, silent = true, buffer = 0 }

  vim.keymap.set('n', 't', M.toggle, opts)
  vim.keymap.set('n', 'j', M.next_task, opts)
  vim.keymap.set('n', 'k', M.prev_task, opts)
  vim.keymap.set('n', 'n', M.new_task, opts)
  vim.keymap.set('n', 'za', 'za', opts)  -- toggle fold
  vim.keymap.set('n', 'zc', 'zc', opts)  -- close fold
  vim.keymap.set('n', 'zo', 'zo', opts)  -- open fold
  vim.keymap.set('n', 'zM', 'zM', opts)  -- close all folds
  vim.keymap.set('n', 'zR', 'zR', opts)  -- open all folds
end

-- --------------------------
-- Autocommands
-- --------------------------
vim.cmd [[
  augroup TodoFile
    autocmd!
    autocmd BufRead,BufNewFile *.todo setlocal filetype=todo
    autocmd FileType todo lua require('himadri.todo').setup_syntax()
    autocmd FileType todo lua require('himadri.todo').setup_keymaps()
    autocmd FileType todo lua require('himadri.todo').setup_folds()
  augroup END
]]

return M
