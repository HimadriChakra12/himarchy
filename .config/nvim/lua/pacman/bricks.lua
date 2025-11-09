# bricks.lua
local M = {}

local plugin_file = vim.fn.stdpath("config") .. "/lua/plugs.lua"
local temp_dir = vim.fn.stdpath("cache") .. "/gh_plugin_preview"

-- Save plugin list (only URL)
local function save_plugins(plugins)
  local f = io.open(plugin_file, "w")
  if not f then
    vim.cmd("echohl ErrorMsg | echom 'Could not save plugin file' | echohl None")
    return
  end

  f:write("return {\n")
  for _, p in ipairs(plugins) do
    f:write(string.format("  { url = %q },\n", p.url))
  end
  f:write("}\n")
  f:close()
end

-- Extract name from GitHub URL: "https://github.com/user/repo" → "repo"
local function extract_plugin_name(url)
  return url:match(".*/(.-)$"):gsub("%.git$", "")
end

-- Add plugin by URL
local function add_plugin(url)
  local plugins = require("pacman.ghost").load_plugins()
  for _, p in ipairs(plugins) do
    if p.url == url then
      vim.cmd("echo 'Plugin already exists: " .. url .. "'")
      return
    end
  end
  table.insert(plugins, { url = url })
  save_plugins(plugins)
  vim.cmd("echo 'Plugin added: " .. url .. "'")
end

-- File reader
local function read_file_lines(path)
  local lines = {}
  local f = io.open(path, "r")
  if f then
    for line in f:lines() do
      table.insert(lines, line)
    end
    f:close()
  else
    table.insert(lines, "README not found.")
  end
  return lines
end

-- Telescope GitHub plugin search
function M.find_plugin()
  vim.ui.input({ prompt = "Plugin search: " }, function(input)
    if not input or input == "" then return end

    local Job = require("plenary.job")
    local pickers = require("telescope.pickers")
    local finders = require("telescope.finders")
    local previewers = require("telescope.previewers")
    local actions = require("telescope.actions")
    local action_state = require("telescope.actions.state")
    local conf = require("telescope.config").values

    Job:new({
      command = "gh",
      args = { "search", "repos", input, "--limit", "50", "--json", "name,owner,url" },
      on_exit = function(j)
        vim.schedule(function()
          local results = vim.json.decode(table.concat(j:result(), "\n"))
          if not results then
            vim.cmd("echo 'No results from GitHub'")
            return
          end

          local entries = {}
          for _, r in ipairs(results) do
            table.insert(entries, {
              display = r.owner.login .. "/" .. r.name,
              url = r.url,
            })
          end

          pickers.new({}, {
            prompt_title = "Find Neovim Plugin",
            finder = finders.new_table({
              results = entries,
              entry_maker = function(entry)
                return {
                  value = entry,
                  display = entry.display,
                  ordinal = entry.display,
                }
              end,
            }),
            previewer = previewers.new_buffer_previewer({
              title = "README.md Preview",
              define_preview = function(self, entry, _)
                local temp_dir = vim.fn.stdpath("cache") .. "/plugpreview"
                vim.fn.delete(temp_dir, "rf")
                vim.fn.mkdir(temp_dir, "p")

                local plugin_name = extract_plugin_name(entry.value.url)
                local path = temp_dir .. "/" .. plugin_name

                Job:new({
                  command = "gh",
                  args = { "repo", "clone", entry.value.url, path },
                  on_exit = function()
                    local content = { "No preview available." }
                    for _, file in ipairs({ "README.md", "readme.md", "lua/init.lua" }) do
                      local fullpath = path .. "/" .. file
                      if vim.fn.filereadable(fullpath) == 1 then
                        content = read_file_lines(fullpath)
                        break
                      end
                    end
                    vim.schedule(function()
                      if self.state and vim.api.nvim_buf_is_valid(self.state.bufnr) then
                        vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, content)
                      end
                    end)
                  end,
                }):start()
              end,
            }),
            sorter = conf.generic_sorter(),
            attach_mappings = function(prompt_bufnr, map)
              actions.select_default:replace(function()
                local entry = action_state.get_selected_entry()
                local plugin_url = entry.value.url
                local plugin_name = extract_plugin_name(plugin_url)
                local install_path = vim.fn.stdpath("data") .. "/site/pack/manual/start/" .. plugin_name

                actions._close(prompt_bufnr)

                Job:new({
                  command = "git",
                  args = { "clone", plugin_url, install_path },
                  on_exit = function()
                    vim.schedule(function()
                      local ok, plugmod = pcall(require, "pacman.ghost")
                      if not ok then
                        vim.notify("❌ pacman.ghost not found", vim.log.levels.ERROR)
                        return
                      end
                      local plugins = plugmod.load_plugins()
                      table.insert(plugins, { url = plugin_url })
                      plugmod.save_plugins(plugins)
                      vim.cmd("packadd " .. plugin_name)
                      vim.notify("Installed: " .. plugin_name, vim.log.levels.INFO)
                    end)
                  end,
                }):start()
              end)
              return true
            end,
          }):find()
        end)
      end,
    }):start()
  end)
end

return M
