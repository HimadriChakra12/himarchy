local M = {}

local config_path = vim.fn.stdpath("config")
local plugins_file = config_path .. "/lua/plugs.lua"

-- Extract name from URL
local function extract_name(url)
  return url:match(".*/(.-)%.git$") or url:match(".*/(.-)$")
end

local function load_plugins()
  local status, plugins = pcall(dofile, plugins_file)
  if not status or type(plugins) ~= "table" then
    vim.notify("Failed to load plugin list", vim.log.levels.ERROR)
    return {}
  end

  local f = io.open(plugins_file, "r")
  if not f then return plugins end
  local file_data = f:read("*a")
  f:close()

  for _, p in ipairs(plugins) do
    -- Capture full config function (multi-line, braces, etc.)
    local pat = 'name%s*=%s*"' .. p.name .. '".-config%s*=%s*(function%s*%b().-end)%s*,?'
    local fn_block = file_data:match(pat)
    if fn_block then
      -- store exactly what was found, no extra comma
      p._original_config_text = fn_block
    end
  end

  return plugins
end

-- Append new plugin to plugs.lua without reformatting whole file
local function append_plugin(plugin)
  -- Read current file content
  local f = io.open(plugins_file, "r")
  if not f then
    vim.notify("Failed to open plugins file for appending", vim.log.levels.ERROR)
    return false
  end
  local content = f:read("*a")
  f:close()

  -- Find the position to insert before the final closing '}\n'
  local insert_pos = content:match("()}\n?$")
  if not insert_pos then
    vim.notify("Invalid plugins file format: missing closing brace", vim.log.levels.ERROR)
    return false
  end

  -- Build plugin text block
  local plugin_lines = {}
  table.insert(plugin_lines, "  {")
  table.insert(plugin_lines, string.format('    name = %q,', plugin.name))
  table.insert(plugin_lines, string.format('    url = %q,', plugin.url))

  if plugin.dependencies and #plugin.dependencies > 0 then
    table.insert(plugin_lines, "    dependencies = {")
    for _, d in ipairs(plugin.dependencies) do
      table.insert(plugin_lines, string.format('      { url = %q },', d.url))
    end
    table.insert(plugin_lines, "    },")
  end

  if plugin._original_config_text then
    table.insert(plugin_lines, "    config = " .. plugin._original_config_text)
  elseif plugin.config then
    table.insert(plugin_lines, "    config = function()")
    table.insert(plugin_lines, string.format("      require(%q)", plugin.name))
    table.insert(plugin_lines, "    end,")
  end

  table.insert(plugin_lines, "  },")
  local plugin_text = table.concat(plugin_lines, "\n") .. "\n"

  -- Insert new plugin text before closing brace
  local new_content = content:sub(1, insert_pos - 1) .. plugin_text .. content:sub(insert_pos)

  -- Write back
  local wf = io.open(plugins_file, "w")
  if not wf then
    vim.notify("Failed to write plugins file", vim.log.levels.ERROR)
    return false
  end
  wf:write(new_content)
  wf:close()
  return true
end

-- Format plugins for display
local function format_plugins(plugins)
  local lines = {}
  for _, plugin in ipairs(plugins) do
    table.insert(lines, plugin.name .. " (" .. plugin.url .. ")")
    if plugin.dependencies then
      for _, dep in ipairs(plugin.dependencies) do
        local dep_name = extract_name(dep.url)
        table.insert(lines, "  [>] " .. dep_name .. " (" .. dep.url .. ")")
      end
    end
    table.insert(lines, "")
  end
  return lines
end

-- Parse dependencies input like "<url> ; <url>"
local function parse_dependencies(dep_input)
  if not dep_input or dep_input == "" then return nil end
  local deps = {}
  for dep_str in dep_input:gmatch("[^;]+") do
    local url = dep_str:match("^%s*(%S+)%s*$")
    if url then
      table.insert(deps, { url = url })
    end
  end
  if #deps == 0 then return nil end
  return deps
end

-- Refresh the buffer view
local function refresh_buffer(bufnr, plugins)
  local lines = format_plugins(plugins)
  vim.api.nvim_buf_set_option(bufnr, "modifiable", true)
  vim.api.nvim_buf_set_lines(bufnr, 1, -1, false, lines)
  vim.api.nvim_buf_set_option(bufnr, "modifiable", false)
end

-- Add plugin
local function add_plugin(bufnr, plugins)
  vim.ui.input({ prompt = "Enter plugin name (e.g. lualine.nvim): " }, function(name)
    if not name or name == "" then return end
    vim.ui.input({ prompt = "Enter plugin URL: " }, function(url)
      if not url or url == "" then return end
      vim.ui.input({ prompt = "Enter dependencies (URLs separated by `;`), or leave empty: " }, function(dep_input)
        local deps = parse_dependencies(dep_input)
        local clean_name = name:gsub("%.nvim$", "")

        local new_plugin = {
          name = clean_name,
          url = url,
          dependencies = deps,
          config = function()
            require(clean_name)
          end,
        }

        -- Append plugin to file without rewriting all plugins
        if append_plugin(new_plugin) then
          vim.notify("Plugin added, reloading...")
          -- Add to plugins list in-memory for UI refresh
          table.insert(plugins, new_plugin)
          refresh_buffer(bufnr, plugins)

          -- Open plugs.lua after saving for tweaking
          vim.cmd("edit " .. plugins_file)
          vim.api.nvim_create_autocmd("BufWritePost", {
            pattern = "plugs.lua",
            callback = function()
              vim.schedule(function()
                vim.cmd("PacmanSync")
              end)
            end,
            once = true, -- Run only once per session
          })
          vim.api.nvim_create_autocmd("BufWritePost", {
            pattern = "plugs.lua",
            callback = function()
              vim.schedule(function()
                vim.cmd("source lua/plugs.lua")
              end)
            end,
            once = true, -- Run only once per session
          })
          vim.api.nvim_create_autocmd("BufWritePost", {
            pattern = "plugs.lua",
            callback = function()
              vim.schedule(function()
                vim.cmd("source $MYVIMRC")
              end)
            end,
            once = true, -- Run only once per session
          })
        end
      end)
    end)
  end)
end

-- Delete plugin or dependency (UI only, no file modification)
-- Delete plugin or dependency from file and UI, preserving other plugin configs
local function delete_at_cursor(bufnr, plugins)
  local cursor = vim.api.nvim_win_get_cursor(0)
  local line = cursor[1]
  if line == 1 then return end

  -- Read full file content
  local f = io.open(plugins_file, "r")
  if not f then
    vim.notify("Failed to open plugins file", vim.log.levels.ERROR)
    return
  end
  local content = f:read("*a")
  f:close()

  local idx = 2
  for i, p in ipairs(plugins) do
    local plugin_line = idx
    local dep_count = p.dependencies and #p.dependencies or 0
    local dep_lines = {}
    for d = 1, dep_count do
      table.insert(dep_lines, idx + d)
    end

    -- If cursor is on the plugin itself
    if line == plugin_line then
      -- Remove the plugin block from file
      local pat = '(%s*{%s*name%s*=%s*"' .. p.name .. '".-},?\n)'
      content = content:gsub(pat, "", 1)

      table.remove(plugins, i)
      vim.notify("Plugin deleted")
      refresh_buffer(bufnr, plugins)

      local wf = io.open(plugins_file, "w")
      if wf then
        wf:write(content)
        wf:close()
      else
        vim.notify("Failed to write plugins file", vim.log.levels.ERROR)
      end
      return
    end

    -- If cursor is on a dependency
    for di, dline in ipairs(dep_lines) do
      if line == dline then
        local dep_url = p.dependencies[di].url
        -- Remove dependency line from file
        local dep_pat = '({%s*url%s*=%s*"' .. dep_url .. '"%s*},?\n)'
        content = content:gsub(dep_pat, "", 1)

        table.remove(p.dependencies, di)
        if #p.dependencies == 0 then p.dependencies = nil end

        vim.notify("Dependency deleted")
        refresh_buffer(bufnr, plugins)

        local wf = io.open(plugins_file, "w")
        if wf then
          wf:write(content)
          wf:close()
        else
          vim.notify("Failed to write plugins file", vim.log.levels.ERROR)
        end
        return
      end
    end

    idx = idx + dep_count + 2
  end

  vim.notify("No plugin or dependency found on this line", vim.log.levels.WARN)
end

-- Git pull update
local function update_plugins()
  vim.notify("Syncing.....")
  local plugins = load_plugins()
  for _, plugin in ipairs(plugins) do
    local plugin_dir = vim.fn.stdpath("data") .. "/site/pack/manual/start/" .. plugin.name
    if vim.fn.isdirectory(plugin_dir) == 1 then
      vim.fn.system({ "git", "-C", plugin_dir, "pull" })
    end
    if plugin.dependencies then
      for _, dep in ipairs(plugin.dependencies) do
        local dep_name = extract_name(dep.url)
        local dep_dir = vim.fn.stdpath("data") .. "/site/pack/manual/start/" .. dep_name
        if vim.fn.isdirectory(dep_dir) == 1 then
          vim.fn.system({ "git", "-C", dep_dir, "pull" })
        end
      end
    end
  end
  vim.notify("Plugins Updated.")
end

-- Open plugin manager UI
function M.open()
  local plugins = load_plugins()
  local lines = format_plugins(plugins)

  vim.cmd("belowright new")
  local bufnr = vim.api.nvim_get_current_buf()

  vim.bo[bufnr].buftype = "nofile"
  vim.bo[bufnr].bufhidden = "wipe"
  vim.bo[bufnr].swapfile = false
  vim.bo[bufnr].modifiable = true

  vim.api.nvim_buf_set_name(bufnr, "Plugin Manager")
  vim.api.nvim_buf_set_lines(bufnr, 1, -1, false, lines)
  vim.bo[bufnr].modifiable = false

  local opts = { noremap = true, silent = true, buffer = bufnr }

  vim.keymap.set("n", "q", ":close<CR>", opts)
  vim.keymap.set("n", "a", function() add_plugin(bufnr, plugins) end, opts)
  vim.keymap.set("n", "d", function() delete_at_cursor(bufnr, plugins) end, opts)
  vim.keymap.set("n", "s", function() update_plugins() end, opts)
  vim.keymap.set("n", "u", "u", opts)
end

return M
