local M = {}
M.pin_buf = {}

-- Toggle pin for current buffer
function M.toggle_pin()
  local buf = vim.api.nvim_get_current_buf()
  if M.pin_buf[buf] then
    M.pin_buf[buf] = nil
    print("Unpinned buffer: " .. vim.api.nvim_buf_get_name(buf))
  else
    M.pin_buf[buf] = true
    print("Pinned buffer: " .. vim.api.nvim_buf_get_name(buf))
  end
end

-- Telescope buffers picker with pins + previewer
function M.buffers_with_pins(opts)
  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  local conf = require("telescope.config").values
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")

  opts = opts or {}

  local entries = {}

  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) then
      local name = vim.api.nvim_buf_get_name(buf)
      if name == "" then name = "[No Name]" end

      local display = M.pin_buf[buf] and ("[SAY] " .. name) or name

      table.insert(entries, {
        value = buf,        -- real bufnr
        display = display,  -- shown in telescope
        ordinal = name,     -- used for sorting
        filename = name,    -- required for previewer
      })
    end
  end

  -- Sort so pinned appear first
  table.sort(entries, function(a, b)
    local a_pinned = M.pin_buf[a.value] and 1 or 0
    local b_pinned = M.pin_buf[b.value] and 1 or 0
    if a_pinned ~= b_pinned then
      return a_pinned > b_pinned
    end
    return a.ordinal < b.ordinal
  end)

  pickers.new(opts, {
    prompt_title = "Buffers",
    finder = finders.new_table({
      results = entries,
      entry_maker = function(entry) return entry end,
    }),
    sorter = conf.generic_sorter(opts),
    previewer = conf.grep_previewer(opts), -- 📌 enables preview
    attach_mappings = function(prompt_bufnr, map)
      actions.select_default:replace(function()
        local selection = action_state.get_selected_entry()
        actions.close(prompt_bufnr)
        if selection and selection.value then
          vim.cmd("buffer " .. selection.value)
        end
      end)
      return true
    end,
  }):find()
end

return M
