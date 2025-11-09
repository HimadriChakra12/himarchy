--  Function to highlight function start and end lines
local function highlight_function_markers()
  local current_buf = vim.api.nvim_get_current_buf()
  local lines = vim.api.nvim_buf_get_lines(current_buf, 0, -1, false)
  local start_pattern = "^function%s*(%([^)]*%))?%s*{" -- Matches "function(){" or "function(args){"
  local end_pattern = "^end$"

  local start_matches = {}
  local end_matches = {}

  -- Find matching lines
  for i, line in ipairs(lines) do
    if string.match(line, start_pattern) then
      table.insert(start_matches, i - 1) -- Adjust index to be 0-based
    elseif string.match(line, end_pattern) then
      table.insert(end_matches, i - 1) -- Adjust index to be 0-based
    end
  end

  -- Define highlight group (if it doesn't exist)
  vim.cmd('hi FunctionMarker guifg=#FF00FF guibg=NONE ctermfg=magenta ctermbg=NONE')

  -- Clear previous highlights in the current buffer
  vim.api.nvim_buf_clear_namespace(current_buf, vim.api.nvim_create_namespace('function_markers'), 0, -1)

  -- Apply highlights to start lines
  for _, line_nr in ipairs(start_matches) do
    vim.api.nvim_buf_add_highlight(current_buf, vim.api.nvim_create_namespace('function_markers'), 'FunctionMarker', line_nr, 0, -1)
  end

  -- Apply highlights to end lines
  for _, line_nr in ipairs(end_matches) do
    vim.api.nvim_buf_add_highlight(current_buf, vim.api.nvim_create_namespace('function_markers'), 'FunctionMarker', line_nr, 0, -1)
  end
end

-- Automatically run the highlighting function on BufEnter (when a buffer is opened)
vim.api.nvim_create_autocmd("BufEnter", {
  callback = highlight_function_markers,
})

-- You might also want to trigger it on BufWritePost (after saving) or other relevant events
vim.api.nvim_create_autocmd("BufWritePost", {
  callback = highlight_function_markers,
})
