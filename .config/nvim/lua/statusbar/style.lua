local function is_git_repo()
  local git_dir = vim.fn.finddir(".git", ";")
  return git_dir ~= ""
end

local function get_git_branch()
  if not is_git_repo() then return "" end

  -- get current branch
  local branch = vim.fn.systemlist("git branch --show-current")[1]
  if not branch or branch == "" then return "" end

  -- trim line endings (Windows safe)
  branch = branch:gsub("%s+", "")

  -- get list of branches
  local branches = vim.fn.systemlist("git branch --format='%(refname:short)'")
  local count = 0
  for _, b in ipairs(branches) do
    if b and b:gsub("%s+", "") ~= "" then
      count = count + 1
    end
  end

  -- show [M] if main/master or only one branch
  if branch == "main" or branch == "master" or count == 1 then
    return "M"
  else
    return "b"
  end
end
local function get_git_status()
  local status = vim.fn.systemlist("git status --porcelain")[1]
  if status and status ~= "" then
    return " " --  is a git status icon
  else
    return ""
  end
end

-- style
-- vim.opt.statusline = "Him[%f] %= %#LineNr# %y %p%% %#StatusLineMode#" .. get_git_branch() .. get_git_status() ..  "%#StatusLine# [%L:%c]"
-- [v] vim.opt.statusline = "%{toupper(mode())}[%f] %=%{luaeval('get_buffers()')}%= %#LineNr# %y %p%% %#StatusLineMode#%{get(g:, 'get_git_branch', '')}%{get(g:, 'get_git_status', '')}%#StatusLine# [%L:%c]"
-- [x] vim.opt.statusline = "%{%v:lua.get_mode()%}[%f] %=%{luaeval('get_buffers()')}%= %#LineNr# %y %p%% %#StatusLineMode#%{get(g:, 'get_git_branch', '')}%{get(g:, 'get_git_status', '')}%#StatusLine# [%L:%c]"
-- vim.opt.statusline = "[%{toupper(mode())}] | %{luaeval('get_buffers()')}%=  |%#LineNr# %y %m %p%% %#StatusLineMode# " .. get_git_branch() .. get_git_status() ..  " %#StatusLine# %l:%L:%c  "

local buffer_list = {}

local function update_buffers()
  buffer_list = {}
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) then
      local name = vim.api.nvim_buf_get_name(buf)
      if name ~= "" then
        table.insert(buffer_list, {
          id = buf,
          name = vim.fn.fnamemodify(name, ":t"), -- Get only filename, no path
          current = buf == vim.api.nvim_get_current_buf()
        })
      end
    end
  end
end

local function get_buffers()
  update_buffers()
  local parts = {}
  for _, buf in ipairs(buffer_list) do
    table.insert(parts, buf.current and ("[%s]"):format(buf.name) or buf.name)
  end
  return table.concat(parts, " / ")
end

-- Set up autocmds to update buffers
vim.api.nvim_create_autocmd({"BufEnter", "BufAdd", "BufDelete"}, {
  pattern = "*",
  callback = update_buffers
})

-- Initialize the buffer list
update_buffers()

vim.opt.statusline = "[%{toupper(mode())}] [%L:%c] %m %= [ %f ] %= %y %p%% %#StatusLineMode#" .. get_git_branch() .. get_git_status() ..  "%#StatusLine# "

_G.get_buffers = get_buffers
vim.opt.showmode = false
