-- Cycle through buffers with Tab and Shift+Tab

local function cycle_buffers(direction)
  local current_buf = vim.api.nvim_get_current_buf()
  local buffers = vim.api.nvim_list_bufs()
  local visible_buffers = {}

  -- Filter out hidden or unloaded buffers
  for _, buf in ipairs(buffers) do
    if vim.api.nvim_buf_is_loaded(buf) then
      table.insert(visible_buffers, buf)
    end
  end

  local current_index = -1
  for i, buf in ipairs(visible_buffers) do
    if buf == current_buf then
      current_index = i
      break
    end
  end

  if current_index == -1 then
    return -- Current buffer not found (shouldn't happen)
  end

  local next_index = current_index + direction
  if next_index < 1 then
    next_index = #visible_buffers
  elseif next_index > #visible_buffers then
    next_index = 1
  end

  vim.api.nvim_command("buffer " .. visible_buffers[next_index])
end

-- Map Tab and Shift+Tab
vim.keymap.set("n", "<Tab>", function() cycle_buffers(1) end, { desc = "Next buffer" })
vim.keymap.set("n", "<S-Tab>", function() cycle_buffers(-1) end, { desc = "Previous buffer" })

-- Example usage in nvim:
-- <Tab> to cycle forward
-- <Shift+Tab> to cycle backward

vim.keymap.set('n', '<leader>1', ':buffer 1<CR>',{ desc = 'Go to buffer 1', silent = true })
vim.keymap.set('n', '<leader>2', ':buffer 2<CR>',{ desc = 'Go to buffer 2', silent = true })
vim.keymap.set('n', '<leader>3', ':buffer 3<CR>',{ desc = 'Go to buffer 3', silent = true })
vim.keymap.set('n', '<leader>4', ':buffer 4<CR>',{ desc = 'Go to buffer 4', silent = true })
vim.keymap.set('n', '<leader>5', ':buffer 5<CR>',{ desc = 'Go to buffer 5', silent = true })
vim.keymap.set('n', '<leader>6', ':buffer 6<CR>',{ desc = 'Go to buffer 6', silent = true })
vim.keymap.set('n', '<leader>7', ':buffer 7<CR>',{ desc = 'Go to buffer 7', silent = true })
vim.keymap.set('n', '<leader>8', ':buffer 8<CR>',{ desc = 'Go to buffer 8', silent = true })
vim.keymap.set('n', '<leader>9', ':buffer 9<CR>',{ desc = 'Go to buffer 9', silent = true })
