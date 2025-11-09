-- File: ~/.config/nvim/lua/popup_explorer/init.lua

local M = {}

-- Default configuration with VSCode-like styling for terminal
local config = {
  width = 0.8,   -- 80% of editor width for terminal
  height = 0.6,  -- 60% of editor height for terminal
  border = 'single',
  title = " Terminal ",
  title_pos = "center",
  dynamic_colors = true,
  bg_color = nil,
  fg_color = nil,
  border_color = nil,
}

-- Set up configuration
function M.setup(user_config)
  config = vim.tbl_deep_extend("force", config, user_config or {})
end

-- Get dynamic colors based on current colorscheme
local function get_colors()
  if not config.dynamic_colors then
    return {
      bg = config.bg_color or "Normal",
      fg = config.fg_color or "Normal",
      border = config.border_color or "FloatBorder",
    }
  end

  -- Try to get colors from current highlight groups
  local bg = vim.fn.synIDattr(vim.fn.synIDtrans(vim.fn.hlID("Normal")), "bg#")
  local fg = vim.fn.synIDattr(vim.fn.synIDtrans(vim.fn.hlID("Normal")), "fg#")
  local border = vim.fn.synIDattr(vim.fn.synIDtrans(vim.fn.hlID("FloatBorder")), "fg#")


  -- Fallback to VSCode-like colors (can be adjusted for terminal feel)
  if bg == "" then bg = "#1e1e1e" end      -- Dark editor background
  if fg == "" then fg = "#d4d4d4" end      -- Default text color
  if border == "" then border = "#ebdbb2" end -- Subtle border

  return {
    bg = bg,
    fg = fg,
    border = border,
  }
end

-- Create the terminal popup window
function M.open_terminal()
  local colors = get_colors()

  -- Calculate dimensions
  local width = math.floor(vim.o.columns * config.width)
  local height = math.floor(vim.o.lines * config.height)
  local col = math.floor((vim.o.columns - width) / 2) -- Center horizontally
  local row = math.floor((vim.o.lines - height) / 2)  -- Center vertically

  -- Create a scratch buffer for the terminal
  local term_buf = vim.api.nvim_create_buf(true, true) -- Set `listed` to false
  vim.api.nvim_buf_set_name(term_buf, "popup-terminal")

  -- Set buffer options
  vim.api.nvim_buf_set_option(term_buf, 'buftype', 'nofile')
  vim.api.nvim_buf_set_option(term_buf, 'swapfile', false)
  vim.api.nvim_buf_set_option(term_buf, 'bufhidden', 'wipe')
  vim.api.nvim_buf_set_option(term_buf, 'modifiable', false) -- Terminal buffer should not be modifiable

  -- Create the window
  local win = vim.api.nvim_open_win(term_buf, true, {
    relative = 'editor',
    width = width,
    height = height,
    col = col,
    row = row,
    style = 'minimal',
    border = config.border,
    title = config.title,
    title_pos = config.title_pos,
  })

  -- Set window options
  vim.api.nvim_win_set_option(win, 'number', false)
  vim.api.nvim_win_set_option(win, 'relativenumber', false)
  vim.api.nvim_win_set_option(win, 'cursorline', false) -- No cursor line in terminal
  vim.api.nvim_win_set_option(win, 'wrap', false)
  vim.api.nvim_win_set_option(win, 'signcolumn', 'no')

  -- Set highlight groups
  vim.api.nvim_set_hl(0, 'PopupTerminalNormal', { bg = colors.bg, fg = colors.fg })
  vim.api.nvim_set_hl(0, 'PopupTerminalBorder', { fg = colors.border })

  vim.api.nvim_win_set_option(win, 'winhl',
    'Normal:PopupTerminalNormal,' ..
    'NormalNC:PopupTerminalNormal,' ..
    'FloatBorder:PopupTerminalBorder')

  -- Close window function
  local function close_window()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
  end

  -- Set up key mappings for the terminal window
  local function set_keymap(mode, lhs, rhs, opts)
    local options = vim.tbl_extend("force", {
      noremap = true,
      silent = true,
      buffer = term_buf, -- Ensure the keymap is buffer-local
    }, opts or {})
    vim.keymap.set(mode, lhs, rhs, options)
  end

  -- Set key mappings IMMEDIATELY after buffer creation
  set_keymap('n', '<Esc>', close_window)
  set_keymap('n', 'q', close_window)
  set_keymap('n', '<C-c>', close_window)

  -- Execute the terminal command in the buffer
  vim.api.nvim_command("buffer " .. term_buf)
  vim.api.nvim_command("terminal")

  -- Set up autocommands
  vim.api.nvim_create_autocmd('BufLeave', {
    buffer = buf,
    callback = close_window,
    once = true,
  })

  vim.api.nvim_create_autocmd('DirChanged', {
    callback = function()
      if vim.api.nvim_win_is_valid(win) then
        refresh_contents()
      end
    end,
  })
end

-- Toggle function for terminal
function M.toggle_terminal()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.api.nvim_buf_get_name(buf) == "popup-terminal" then
      vim.api.nvim_win_close(win, true)
      return
    end
  end
  M.open_terminal()
end

-- Command to open the terminal popup
vim.api.nvim_create_user_command('TerminalPopup', M.toggle_terminal, {
  desc = "Toggle terminal in a popup window"
})

return M
