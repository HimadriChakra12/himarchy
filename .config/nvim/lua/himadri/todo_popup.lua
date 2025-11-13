local todo = require("himadri.todo")

local has_telescope, telescope = pcall(require, "telescope")
if not has_telescope then
  vim.notify("Telescope not found", vim.log.levels.WARN)
  return
end

local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values

function todo.telescope_todo_popup()
  pickers.new({}, {
    prompt_title = "TODO Files",
    finder = finders.new_oneshot_job(
      {"find", vim.fn.expand("~/todo"), "-type", "f", "-name", "*.todo"},
      {}
    ),
    sorter = conf.generic_sorter({}),
    attach_mappings = function(prompt_bufnr, map)
      actions.select_default:replace(function()
        local selection = action_state.get_selected_entry()
        actions.close(prompt_bufnr)
        -- Ensure we get the path string
        local filepath = nil
        if type(selection) == "table" then
          filepath = selection[1] or selection.value  -- some versions return `value`
        else
          filepath = selection
        end
        if filepath then
          todo.open_popup(filepath)
        else
          vim.notify("Failed to get file path!", vim.log.levels.ERROR)
        end
      end)
      return true
    end
  }):find()
end
