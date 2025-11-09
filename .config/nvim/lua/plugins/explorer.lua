-- File: ~/.config/nvim/lua/popup_explorer/init.lua

local M = {}

-- Default configuration with VSCode-like styling
local config = {
  width = 1.0,  -- 30% of editor width
  height = 0.2, -- 70% of editor height
  border = 'single',
  title = "  Explorer  ",
  title_pos = "left",
  dynamic_colors = true,
  bg_color = nil,
  fg_color = nil,
  border_color = nil,
  directory_color = "#4EC9B0",  -- VSCode folder blue-green
  file_color = "#D4D4D4",       -- VSCode default text color
  icon_style = "vscode",        -- "vscode" or "none"
  indent_width = 2,             -- Indentation for nested items
  show_hidden = false,          -- Show hidden files by default
}

-- State for cut/yank/paste
local clipboard = {}
local clipboard_mode = nil -- "cut" or "copy"
local selected_indices = {}

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
      directory = config.directory_color,
      file = config.file_color,
    }
  end

  -- Try to get colors from current highlight groups
  local bg = vim.fn.synIDattr(vim.fn.synIDtrans(vim.fn.hlID("Normal")), "bg#")
  local fg = vim.fn.synIDattr(vim.fn.synIDtrans(vim.fn.hlID("Normal")), "fg#")
  local border = vim.fn.synIDattr(vim.fn.synIDtrans(vim.fn.hlID("FloatBorder")), "fg#")
  
  -- Fallback to VSCode-like colors
  if bg == "" then bg = "#1e1e1e" end       -- Dark editor background
  if fg == "" then fg = "#d4d4d4" end       -- Default text color
  if border == "" then border = "#454545" end -- Subtle border

  return {
    bg = bg,
    fg = fg,
    border = border,
    directory = config.directory_color,
    file = config.file_color,
  }
end

-- Get icon based on file type and configuration
local function get_icon(name, is_directory)
  if config.icon_style ~= "vscode" then
    return ""
  end

  if is_directory then
    return " "  -- Folder icon
  end

  -- Simple file type icons
  local ext = name:match("%.([^%.]+)$") or ""
  local icons = {
    lua = " ",
    js = " ",
    ts = " ",
    json = " ",
    html = " ",
    css = " ",
    scss = " ",
    md = " ",
    py = " ",
    go = " ",
    rs = " ",
    sh = " ",
    zsh = " ",
    vim = " ",
    git = " ",
    LICENSE = " ",
    lock = " ",
    png = " ",
    jpg = " ",
    jpeg = " ",
    gif = " ",
    svg = " ",
  }

  return icons[ext] or (name:match("^%.") and " " or " ")  -- Default file icon or dotfile icon
end

-- Create the popup window
function M.open()
  local colors = get_colors()

  -- Calculate dimensions
  local width = math.floor(vim.o.columns * config.width)
  local height = math.floor(vim.o.lines * config.height)
  local col = math.floor((vim.o.columns - width) / 1) -- Center horizontally
  local row = math.floor((vim.o.lines - height) / 1)  -- Center vertically

  -- Create a scratch buffer for the file explorer
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_name(buf, "popup-explorer")

  -- Set buffer options
  vim.api.nvim_buf_set_option(buf, 'buftype', 'nofile')
  vim.api.nvim_buf_set_option(buf, 'swapfile', false)
  vim.api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')
  vim.api.nvim_buf_set_option(buf, 'modifiable', true)

  -- Create the window
  local win = vim.api.nvim_open_win(buf, true, {
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
  vim.api.nvim_win_set_option(win, 'cursorline', true)
  vim.api.nvim_win_set_option(win, 'wrap', false)
  vim.api.nvim_win_set_option(win, 'signcolumn', 'no')

  -- Set highlight groups
  vim.api.nvim_set_hl(0, 'PopupExplorerNormal', { bg = colors.bg, fg = colors.fg })
  vim.api.nvim_set_hl(0, 'PopupExplorerBorder', { fg = colors.border })
  vim.api.nvim_set_hl(0, 'PopupExplorerDirectory', { fg = colors.directory, bold = true })
  vim.api.nvim_set_hl(0, 'PopupExplorerFile', { fg = colors.file })
  vim.api.nvim_set_hl(0, 'PopupExplorerCursorLine', { bg = "#2a2d2e" }) -- VSCode-like selection color
  vim.api.nvim_set_hl(0, 'PopupExplorerSymlink', { fg = "#569CD6", italic = true })
  vim.api.nvim_set_hl(0, 'PopupExplorerHidden', { fg = "#6A9955", italic = true })

  vim.api.nvim_win_set_option(win, 'winhl', 
    'Normal:PopupExplorerNormal,' ..
    'NormalNC:PopupExplorerNormal,' ..
    'FloatBorder:PopupExplorerBorder,' ..
    'CursorLine:PopupExplorerCursorLine')

  -- Current path tracking
  local current_path = vim.fn.getcwd()
  local path_history = { current_path }
  local history_index = 1

  -- Function to get directory contents
  local function get_directory_contents(path)
    local files = {}
    local dirs = {}

    -- Read directory contents
    local success, entries = pcall(vim.fn.readdir, path, function(entry)
      if config.show_hidden then
        return true
      end
      return not entry:match("^%.")
    end)

    if not success then
      return nil, entries
    end

    -- Separate directories and files
    for _, entry in ipairs(entries) do
      local full_path = path .. "/" .. entry
      local stat = vim.loop.fs_stat(full_path)
      if stat then
        if stat.type == "directory" then
          table.insert(dirs, { name = entry, path = full_path, stat = stat })
        elseif stat.type == "link" then
          table.insert(files, { name = entry, path = full_path, stat = stat, is_link = true })
        else
          table.insert(files, { name = entry, path = full_path, stat = stat })
        end
      end
    end

    -- Sort alphabetically (directories first)
    table.sort(dirs, function(a, b) return a.name:lower() < b.name:lower() end)
    table.sort(files, function(a, b) return a.name:lower() < b.name:lower() end)

    return dirs, files
  end

  -- Function to populate the buffer with directory contents
  local function refresh_contents()
    vim.api.nvim_buf_set_option(buf, 'modifiable', true)
    
    local dirs, files, err = get_directory_contents(current_path)
    if err then
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "Error reading directory: " .. err })
      vim.api.nvim_buf_set_option(buf, 'modifiable', false)
      return
    end

    -- Prepare lines with icons and proper coloring
    local lines = {}
    local highlights = {}

    -- Add parent directory entry
    if current_path ~= "/" then
      table.insert(lines, " ../")
      table.insert(highlights, {
        line = #lines - 1,
        col = 0,
        end_col = #lines[#lines],
        hl_group = 'PopupExplorerDirectory'
      })
    end

    -- Add directories
    for _, dir in ipairs(dirs) do
      local icon = get_icon(dir.name, true)
      local line = icon .. dir.name .. "/"
      table.insert(lines, line)
      
      local hl_group = dir.name:match("^%.") and 'PopupExplorerHidden' or 'PopupExplorerDirectory'
      table.insert(highlights, {
        line = #lines - 1,
        col = 0,
        end_col = #line,
        hl_group = hl_group
      })
    end

    -- Add files
    for _, file in ipairs(files) do
      local icon = get_icon(file.name, false)
      local line = icon .. file.name
      table.insert(lines, line)
      
      local hl_group = 'PopupExplorerFile'
      if file.is_link then
        hl_group = 'PopupExplorerSymlink'
      elseif file.name:match("^%.") then
        hl_group = 'PopupExplorerHidden'
      end
      
      table.insert(highlights, {
        line = #lines - 1,
        col = 0,
        end_col = #line,
        hl_group = hl_group
      })
    end
    -- Highlight selected lines
    for i = 1, #lines do
        if selected_indices[i] then
            table.insert(highlights, {
                line = i - 1,
                col = 0,
                end_col = #lines[i],
                hl_group = 'Visual',
            })
        end
    end


    -- Set lines and apply highlights
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    for _, hl in ipairs(highlights) do
      vim.api.nvim_buf_add_highlight(
        buf, -1, hl.hl_group, hl.line, hl.col, hl.end_col
      )
    end
    
    vim.api.nvim_buf_set_option(buf, 'modifiable', false)
  end

  -- Function to change directory
  local function change_directory(new_path)
    current_path = new_path
    -- Update history
    if path_history[history_index] ~= current_path then
      -- Remove any forward history
      while #path_history > history_index do
        table.remove(path_history)
      end
      table.insert(path_history, current_path)
      history_index = #path_history
    end
    refresh_contents()
  end

  -- Function to create a new file or directory
  local function create_new(is_directory)
    vim.api.nvim_buf_set_option(buf, 'modifiable', true)
    
    -- Get current line number
    local line_num = vim.api.nvim_win_get_cursor(win)[1]
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    
    -- Set prompt based on type
    local prompt = is_directory and "New directory name: " or "New file name: "
    
    -- Get input from user
    vim.api.nvim_buf_set_lines(buf, #lines, #lines, false, { prompt })
    vim.api.nvim_win_set_cursor(win, { #lines + 1, #prompt })
    
    -- Enter insert mode
    vim.cmd("startinsert")
    
    -- Set up a callback for when input is complete
    local function on_input()
      local new_name = vim.api.nvim_get_current_line():sub(#prompt + 0)
      if new_name and new_name ~= "" then
        local full_path = current_path .. "/" .. new_name
        
        if is_directory then
          local success, err = pcall(vim.fn.mkdir, full_path, "p")
          if not success then
            vim.notify("Error creating directory: " .. err, vim.log.levels.ERROR)
          end
        else
          local file = io.open(full_path, "w")
          if file then
            file:close()
          else
            vim.notify("Error creating file: " .. full_path, vim.log.levels.ERROR)
          end
        end
        
        refresh_contents()
      else
        -- User cancelled
        refresh_contents()
      end
    end
    
    -- Set up keymaps for the input mode
    vim.api.nvim_buf_set_keymap(buf, "i", "<CR>", "", {
      callback = function()
        vim.cmd("stopinsert")
        on_input()
      end,
      noremap = true,
      silent = true,
    })
    
    vim.api.nvim_buf_set_keymap(buf, "i", "<Esc>", "", {
      callback = function()
        vim.cmd("stopinsert")
        refresh_contents()
      end,
      noremap = true,
      silent = true,
    })
  end

  -- Function to delete a file or directory
  local function delete_current()
    local line_num = vim.api.nvim_win_get_cursor(win)[1]
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    if line_num < 1 or line_num > #lines then return end
    
    local line = lines[line_num]
    local name = line:match("[^%s]+$")  -- Get last non-whitespace segment (after icon)
    if not name then return end
    
    -- Remove trailing slash for directories
    local is_dir = name:sub(-1) == "/"
    if is_dir then
      name = name:sub(1, -2)
    end
    
    local full_path = current_path .. "/" .. name
    
    -- Confirm deletion
    vim.ui.input({
      prompt = string.format("Delete %s '%s'? (y/n): ", is_dir and "directory" or "file", name),
    }, function(input)
      if input and input:lower() == "y" then
        local success, err
        if is_dir then
          success, err = pcall(vim.fn.delete, full_path, "rf")
        else
          success, err = pcall(vim.fn.delete, full_path)
        end
        
        if not success then
          vim.notify("Error deleting: " .. err, vim.log.levels.ERROR)
        else
          refresh_contents()
        end
      end
    end)
  end

  -- Function to rename a file or directory
  local function rename_current()
    local line_num = vim.api.nvim_win_get_cursor(win)[1]
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    if line_num < 1 or line_num > #lines then return end
    
    local line = lines[line_num]
    local old_name = line:match("[^%s]+$")  -- Get last non-whitespace segment (after icon)
    if not old_name then return end
    
    -- Remove trailing slash for directories
    local is_dir = old_name:sub(-1) == "/"
    if is_dir then
      old_name = old_name:sub(1, -2)
    end
    
    local old_path = current_path .. "/" .. old_name
    
    vim.ui.input({
      prompt = string.format("Rename '%s' to: ", old_name),
      default = old_name,
    }, function(new_name)
      if new_name and new_name ~= "" and new_name ~= old_name then
        local new_path = current_path .. "/" .. new_name
        local success, err = pcall(vim.fn.rename, old_path, new_path)
        if not success then
          vim.notify("Error renaming: " .. err, vim.log.levels.ERROR)
        else
          refresh_contents()
        end
      end
    end)
  end

  -- Initial population
  refresh_contents()

  -- Close window function
  local function close_window()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
  end

  -- Set up key mappings
  local function set_keymap(mode, lhs, rhs, opts)
    local options = vim.tbl_extend("force", {
      noremap = true,
      silent = true,
      buffer = buf,
    }, opts or {})
    vim.keymap.set(mode, lhs, rhs, options)
  end

  -- Navigation and basic operations
  set_keymap('n', '<Esc>', close_window)
  set_keymap('n', 'q', close_window)
  set_keymap('n', '<C-c>', close_window)

  set_keymap('n', '<CR>', function()
    local line_num = vim.api.nvim_win_get_cursor(win)[1]
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    if line_num < 1 or line_num > #lines then return end
    
    local line = lines[line_num]
    local name = line:match("[^%s]+$")  -- Get last non-whitespace segment (after icon)
    if not name then return end
    
    if name == "../" then
      -- Go up to parent directory
      change_directory(vim.fn.fnamemodify(current_path, ":h"))
      vim.cmd("pwd")
  elseif name:sub(-1) == "/" then
      -- Enter directory
      change_directory(current_path .. "/" .. name:sub(1, -2))
      vim.cmd("pwd")
    else
      -- Open file
      close_window()
      vim.cmd("edit " .. vim.fn.fnameescape(current_path .. "/" .. name))
    end
  end)

  -- File operations
  set_keymap('n', 'd', delete_current, { desc = "Delete file/directory" })
  set_keymap('n', 'r', rename_current, { desc = "Rename file/directory" })
  set_keymap('n', 'n', function() create_new(false) end, { desc = "Create new file" })
  set_keymap('n', 'N', function() create_new(true) end, { desc = "Create new directory" })

  -- Navigation
  set_keymap('n', 'l', '<CR>')  -- VSCode-like navigation
  set_keymap('n', 'h', function()
    if current_path ~= "/" then
      change_directory(vim.fn.fnamemodify(current_path, ":h"))
    end
  end)

  -- History navigation
  set_keymap('n', '<Left>', function()
    if history_index > 1 then
      history_index = history_index - 1
      current_path = path_history[history_index]
      refresh_contents()
    end
  end)

  set_keymap('n', '<Right>', function()
    if history_index < #path_history then
      history_index = history_index + 1
      current_path = path_history[history_index]
      refresh_contents()
    end
  end)

  -- Toggle hidden files
  set_keymap('n', '.', function()
    config.show_hidden = not config.show_hidden
    refresh_contents()
  end, { desc = "Toggle hidden files" })

  -- Refresh
  set_keymap('n', '<C-r>', refresh_contents, { desc = "Refresh explorer" })

  -- Toggle selection with 'v'
  set_keymap('n', 'v', function()
      local line_num = vim.api.nvim_win_get_cursor(win)[1]
      if selected_indices[line_num] then
          selected_indices[line_num] = nil
      else
          selected_indices[line_num] = true
      end
      refresh_contents()
  end, { desc = "Toggle multi-select" })

  -- Yank selected or single with 'y'
  set_keymap('n', 'y', function()
      clipboard = {}
      clipboard_mode = "copy"
      local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
      for i = 1, #lines do
          if selected_indices[i] or i == vim.api.nvim_win_get_cursor(win)[1] then
              local name = lines[i]:match("[^%s]+$") or ""
              table.insert(clipboard, current_path .. "/" .. name)
          end
      end
      vim.notify("Yanked " .. #clipboard .. " item(s)")
  end)

  -- Cut selected or single with 'x'
  set_keymap('n', 'x', function()
      clipboard = {}
      clipboard_mode = "cut"
      local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
      for i = 1, #lines do
          if selected_indices[i] or i == vim.api.nvim_win_get_cursor(win)[1] then
              local name = lines[i]:match("[^%s]+$") or ""
              table.insert(clipboard, current_path .. "/" .. name)
          end
      end
      vim.notify("Cut " .. #clipboard .. " item(s)")
  end)

  -- Paste with 'p'
  set_keymap('n', 'p', function()
      for _, src in ipairs(clipboard) do
          local name = src:match("[^/\\]+$") -- get basename
          local dest = current_path .. "/" .. name
          if clipboard_mode == "copy" then
              vim.fn.jobstart({ "cmd", "/c", "xcopy", src, dest, "/E", "/I", "/Y" }, { detach = true })
          elseif clipboard_mode == "cut" then
              vim.fn.jobstart({ "cmd", "/c", "move", src, dest }, { detach = true })
          end
      end
      selected_indices = {}
      vim.defer_fn(refresh_contents, 300)
  end)


  -- Set up autocommands
  vim.api.nvim_create_autocmd('BufLeave', {
      buffer = buf,
      callback = close_window,
      once = true,
  })

  vim.api.nvim_create_autocmd('DirChanged', {
      callback = function()
          if vim.api.nvim_win_is_valid(win) then
              change_directory(vim.fn.getcwd())
          end
      end,
  })
end

-- Toggle function
function M.toggle()
    for _, win in ipairs(vim.api.nvim_list_wins()) do
        local buf = vim.api.nvim_win_get_buf(win)
        if vim.api.nvim_buf_get_name(buf) == "popup-explorer" then
            vim.api.nvim_win_close(win, true)
            return
        end
    end
    M.open()
end

-- Command to open the popup
vim.api.nvim_create_user_command('Exp', M.toggle, {
    desc = "Toggle VSCode-like file explorer"
})

return M
