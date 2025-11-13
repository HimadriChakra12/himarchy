local M = require("todo")

local has_telescope, telescope = pcall(require, "telescope")
if not has_telescope then
  vim.notify("Telescope is not installed!", vim.log.levels.WARN)
  return
end

local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local finders = require("telescope.finders")
local pickers = require("telescope.pickers")
local conf = require("telescope.config").values

-- Open a .todo file in popup from Telescope
function M.telescope_todo_popup()
  pickers.new({}, {
    prompt_title = "TODO Files",
    finder = finders.new_oneshot_job({"find", vim.fn.expand("~/todo"), "-type", "f", "-name", "*.todo"}, {}),
    sorter = conf.generic_sorter({}),
    attach_mappings = function(prompt_bufnr, map)
      actions.select_default:replace(function()
        local selection = action_state.get_selected_entry()
        actions.close(prompt_bufnr)
        -- Open the selected file in the floating popup
        M.open_popup(selection[1])
      end)
      return true
    end
  }):find()
end

