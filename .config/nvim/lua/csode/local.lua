local M = {}

M.load = function()
    -- Load nvim_compile plugin
    require("csode.local_plugins.nvim_compile")
    require("csode.local_plugins.markdown_link_nav")
    require("csode.local_plugins.todo")
    require("csode.local_plugins.todo_buffer").setup({
        target_file = "~/notes/todo.md", -- or your preferred path
        width = 0.7,
        height = 0.6,
    })
end

return M
