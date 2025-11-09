-- ghost.lua (async version)
local uv = vim.loop
local M = {}

local data_path = vim.fn.stdpath("data")
local plugin_path = data_path .. "/site/pack/manual/start"
local installed = {}

-- Extract plugin name from Git URL
local function extract_name(url)
  return url:match(".*/(.-)%.git$") or url:match(".*/(.-)$")
end

-- Output buffer utilities
local function open_output_buffer()
  vim.cmd("botright split | resize 10")
  vim.cmd("enew")
  vim.cmd("setlocal buftype=nofile bufhidden=wipe nobuflisted noswapfile")
  local bufnr = vim.api.nvim_get_current_buf()
  return bufnr
end

local function append_lines(bufnr, lines)
  vim.schedule(function()
    local all = {}
    if type(lines) == "string" then
      vim.list_extend(all, vim.split(lines, "\n"))
    elseif type(lines) == "table" then
      for _, l in ipairs(lines) do
        if type(l) == "string" then
          vim.list_extend(all, vim.split(l, "\n"))
        end
      end
    end
    vim.api.nvim_buf_set_lines(bufnr, -1, -1, false, all)
  end)
end

-- Clone a plugin asynchronously
local function clone_plugin_async(url, path, bufnr, on_done)
  append_lines(bufnr, { "o Cloning: " .. url })

  local stdout = uv.new_pipe(false)
  local stderr = uv.new_pipe(false)

  local handle
  handle = uv.spawn("git", {
    args = { "clone", "--depth", "1", url, path },
    stdio = { nil, stdout, stderr },
  }, function(code, signal)
    stdout:close()
    stderr:close()
    handle:close()

    if code == 0 then
      append_lines(bufnr, { "# Clone complete.\n" })
      vim.schedule(function()
        vim.notify("- Installed: " .. extract_name(url), vim.log.levels.INFO)
      end)
      on_done(true)
    else
      append_lines(bufnr, { "X Clone failed with code: " .. tostring(code) })
      vim.schedule(function()
        vim.notify("x Failed: " .. extract_name(url), vim.log.levels.ERROR)
      end)
      on_done(false)
    end
  end)

  local function read_pipe(pipe)
    return function(err, data)
      if err then return end
      if data then append_lines(bufnr, vim.split(data, "\n")) end
    end
  end

  uv.read_start(stdout, read_pipe(stdout))
  uv.read_start(stderr, read_pipe(stderr))
end

-- Ensure a single plugin and its dependencies
local function ensure_plugin(plugin, bufnr, done_cb)
  if not plugin.url then
    append_lines(bufnr, { "!! Skipping plugin with no URL" })
    done_cb()
    return
  end

  local name = extract_name(plugin.url)
  if installed[name] then done_cb(); return end
  installed[name] = true

  local function proceed()
    local path = plugin_path .. "/" .. name
    if not uv.fs_stat(path) then
      append_lines(bufnr, { "|  Installing " .. name .. "..." })
      clone_plugin_async(plugin.url, path, bufnr, function(success)
        vim.schedule(function()
          vim.opt.runtimepath:append(path)
          if success and type(plugin.config) == "function" then
            pcall(plugin.config)
          end
          done_cb()
        end)
      end)
    else
      append_lines(bufnr, { "=  Already installed: " .. name })
      vim.schedule(function()
        vim.opt.runtimepath:append(path)
        if type(plugin.config) == "function" then
          pcall(plugin.config)
        end
        done_cb()
      end)
    end
  end

  if plugin.dependencies and #plugin.dependencies > 0 then
    local i = 1
    local function install_next_dep()
      local dep = plugin.dependencies[i]
      if not dep then return proceed() end
      ensure_plugin(dep, bufnr, function()
        i = i + 1
        install_next_dep()
      end)
    end
    install_next_dep()
  else
    proceed()
  end
end

-- Entry point: async setup
function M.setup()
  -- Force reload plugs.lua module to get fresh data each time
  package.loaded["plugs"] = nil
  local plugins = require("plugs")

  if type(plugins) ~= "table" or #plugins == 0 then
    vim.notify("No plugins found in plugs.lua", vim.log.levels.WARN)
    return
  end

  local bufnr = open_output_buffer()
  append_lines(bufnr, { "/ Starting async installation...\n" })

  local i = 1
  local function install_next()
    local plugin = plugins[i]
    if not plugin then
      append_lines(bufnr, { "\n All plugins installed." })
      -- Delay window close longer to let user see the output
      vim.defer_fn(function()
        for _, win in ipairs(vim.api.nvim_list_wins()) do
          if vim.api.nvim_win_get_buf(win) == bufnr then
            vim.api.nvim_win_close(win, true)
          end
        end
      end, 500) -- 3 seconds delay instead of 500ms
      return
    end

    append_lines(bufnr, { string.format(">> Installing plugin %d/%d: %s", i, #plugins, plugin.name or "unknown") })

    ensure_plugin(plugin, bufnr, function()
      i = i + 1
      install_next()
    end)
  end

  install_next()
end

-- Register a user command

return M
