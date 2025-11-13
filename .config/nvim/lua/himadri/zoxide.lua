-- zox.lua - rewritten zoxide-like Neovim plugin with popup and Telescope

local M = {}
local history_file = vim.fn.stdpath("data") .. "/zox_history.txt"
local history = {}

local config = {
  sort_by = "frecency", -- frecency | recent | frequency
  max_history = 100,
  icon_style = "nerd",   -- nerd | emoji | none
  show_usage = true,
  auto_clean_days = 7,   -- automatically clean entries not used in X days
}

-- Utilities
local function normalize_path(path)
  return vim.fn.fnamemodify(path, ":p"):gsub("\\", "/"):gsub("/+", "/"):gsub("/$", "")
end

local function find_entry(path)
  path = normalize_path(path)
  for i, e in ipairs(history) do
    if normalize_path(e.path) == path then
      return i, e
    end
  end
  return nil, nil
end

local function clean_old_entries()
  local now = os.time()
  local cutoff = now - (config.auto_clean_days * 24 * 60 * 60)
  local new_history = {}
  local seen_paths = {}
  
  for _, entry in ipairs(history) do
    -- Only keep if used recently or path hasn't been seen yet
    if entry.last_used > cutoff or not seen_paths[entry.path] then
      table.insert(new_history, entry)
      seen_paths[entry.path] = true
    end
  end
  
  history = new_history
end

local function update_history(path)
  local i, entry = find_entry(path)
  local now = os.time()
  if entry then
    entry.count = entry.count + 1
    entry.last_used = now
    table.remove(history, i)
  else
    entry = { path = normalize_path(path), count = 1, last_used = now }
  end
  table.insert(history, 1, entry)
  
  -- Clean old entries before enforcing max history
  clean_old_entries()
  
  if #history > config.max_history then 
    table.remove(history) 
  end
end

local function save_history()
  local f = io.open(history_file, "w")
  for _, e in ipairs(history) do
    f:write(string.format("%s|%d|%d\n", e.path, e.count, e.last_used))
  end
  f:close()
end

local function load_history()
  local f = io.open(history_file, "r")
  if not f then return end
  for line in f:lines() do
    local path, count, last = line:match("^(.-)|(%d+)|(%d+)$")
    if path then
      table.insert(history, {
        path = path,
        count = tonumber(count),
        last_used = tonumber(last),
      })
    end
  end
  f:close()
  
  -- Clean old entries when loading history
  clean_old_entries()
end

local function sort_history()
  if config.sort_by == "frecency" then
    table.sort(history, function(a, b)
      local sa = a.count / (os.time() - a.last_used + 1)
      local sb = b.count / (os.time() - b.last_used + 1)
      return sa > sb
    end)
  elseif config.sort_by == "recent" then
    table.sort(history, function(a, b)
      return a.last_used > b.last_used
    end)
  elseif config.sort_by == "frequency" then
    table.sort(history, function(a, b)
      return a.count > b.count
    end)
  end
end

local function fuzzy_filter(query)
  if not query or query == "" then return history end
  local filtered = {}
  local q = query:lower()
  for _, entry in ipairs(history) do
    if entry.path:lower():find(q, 1, true) then
      table.insert(filtered, entry)
    end
  end
  return filtered
end

local function popup_select(results)
  local items = {}
  for _, e in ipairs(results) do
    local icon = config.icon_style == "nerd" and (vim.fn.isdirectory(e.path) == 1 and " " or " ") or ""
    table.insert(items, icon .. vim.fn.fnamemodify(e.path, ":~"))
  end
  vim.ui.select(items, { prompt = "Zox directories" }, function(_, i)
    if i then
      local dir = results[i].path
      vim.cmd("cd " .. vim.fn.fnameescape(dir))
      update_history(dir)
      save_history()
    end
  end)
end

-- Commands
function M.zd(query)
  sort_history()
  local filtered = fuzzy_filter(query)
  if #filtered == 0 then
    vim.notify("No matches", vim.log.levels.WARN)
    return
  end
  popup_select(filtered)
end

function M.zcd(query)
  sort_history()
  local filtered = fuzzy_filter(query)
  if #filtered > 0 then
    local dir = filtered[1].path
    vim.cmd("cd " .. vim.fn.fnameescape(dir))
    update_history(dir)
    save_history()
    vim.cmd("pwd")
  else
    vim.notify("No matches", vim.log.levels.WARN)
  end
end

function M.zt(query)
  local ok, telescope = pcall(require, "telescope")
  if not ok then return end
  sort_history()

  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")
  local conf = require("telescope.config").values
  local previewers = require("telescope.previewers")
  local Job = require("plenary.job")

local function dir_previewer(entry, bufnr)
  local path = entry.value
  if not path or path == "" then return end

  local cmd, args

if vim.fn.has("win32") == 1 then
  cmd = "powershell"
  args = {
    "-NoProfile",
    "-Command",
    string.format(
      "Get-ChildItem -Force -LiteralPath '%s' | Format-Table Mode,Name,Length,LastWriteTime | out-string | Select-String -NotMatch \"^Directory:\"",
      path
    )
  }
  else
    cmd = "ls"
    args = { "-la", path }
  end

  require("plenary.job")
    :new({
      command = cmd,
      args = args,
      on_stdout = function(_, line)
        if line and line ~= "" then
          vim.schedule(function()
            if vim.api.nvim_buf_is_valid(bufnr) then
              vim.api.nvim_buf_set_lines(bufnr, -1, -1, false, { line })
            end
          end)
        end
      end,
      on_stderr = function(_, line)
        if line and line ~= "" then
          vim.schedule(function()
            if vim.api.nvim_buf_is_valid(bufnr) then
              vim.api.nvim_buf_set_lines(bufnr, -1, -1, false, { "Error: " .. line })
            end
          end)
        end
      end,
    })
    :start()
end

  local picker = pickers.new({}, {
    prompt_title = "  Zoxscope  ",
    finder = finders.new_table {
      results = fuzzy_filter(query),
      entry_maker = function(entry)
        return {
          value = entry.path,
          display = vim.fn.fnamemodify(entry.path, ":~"),
          ordinal = entry.path,
        }
      end,
    },
    previewer = previewers.new_buffer_previewer({
      title = "Directory Preview",
      define_preview = function(self, entry, _)
        dir_previewer(entry, self.state.bufnr)
      end,
    }),
    sorter = conf.generic_sorter({}),
    attach_mappings = function(prompt_bufnr, map)
      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        local entry = action_state.get_selected_entry()
        if entry then
          vim.cmd("cd " .. vim.fn.fnameescape(entry.value))
          update_history(entry.value)
          save_history()
          vim.cmd("pwd")
        end
      end)
      return true
    end,
  })

  picker:find()
end

-- Setup and autocmds
function M.setup(user_config)
  config = vim.tbl_deep_extend("force", config, user_config or {})
  load_history()
  
  -- Add autocmd to clean periodically (once per day)
  vim.api.nvim_create_autocmd({"VimEnter"}, {
    callback = function()
      local last_clean_file = vim.fn.stdpath("data") .. "/zox_last_clean.txt"
      local last_clean = 0
      local f = io.open(last_clean_file, "r")
      if f then
        last_clean = tonumber(f:read("*a")) or 0
        f:close()
      end
      
      local now = os.time()
      if now - last_clean > 24 * 60 * 60 then -- 1 day
        clean_old_entries()
        save_history()
        local f = io.open(last_clean_file, "w")
        if f then
          f:write(tostring(now))
          f:close()
        end
      end
    end,
  })
end

vim.api.nvim_create_user_command("Zd", function(opts) M.zd(opts.args) end, { nargs = "?" })
vim.api.nvim_create_user_command("Zcd", function(opts) M.zcd(opts.args) end, { nargs = "?" })
vim.api.nvim_create_user_command("Zt", function(opts) M.zt(opts.args) end, { nargs = "?" })

vim.api.nvim_create_autocmd({"DirChanged", "VimEnter"}, {
  callback = function() update_history(vim.fn.getcwd()); save_history() end,
})

return M
