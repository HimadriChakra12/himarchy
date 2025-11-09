-- File: lua/markdown_link_nav.lua
local M = {}

-- Stack to store history of visited files
local jump_history = {}

-- Main function to follow markdown-style link under cursor
function M.follow_link()
    local line = vim.api.nvim_get_current_line()
    local col = vim.fn.col(".")
    local before_cursor = line:sub(1, col)
    local after_cursor = line:sub(col)

    -- Match markdown link [text](file.md) or Obsidian-style [[file.md]]
    local match = before_cursor:match("%[%[(.-)%]%]")
        or before_cursor:match("%[.-%]%((.-)%)")
        or after_cursor:match("%[.-%]%((.-)%)")

    if match then
        local path = match
        local current_file = vim.api.nvim_buf_get_name(0)
        local base = vim.fn.fnamemodify(current_file, ":h")
        local full_path = vim.fn.fnamemodify(base .. "/" .. path, ":p")

        if vim.fn.filereadable(full_path) == 1 then
            table.insert(jump_history, current_file)
            vim.cmd("edit " .. full_path)
        else
            vim.notify("File not found: " .. full_path, vim.log.levels.WARN)
        end
    else
        vim.notify("No markdown link under cursor", vim.log.levels.INFO)
    end
end

-- Go back to the last visited file
function M.go_back()
    if #jump_history == 0 then
        vim.notify("No previous file in markdown jump history", vim.log.levels.INFO)
        return
    end

    local last_file = table.remove(jump_history)
    if vim.fn.filereadable(last_file) == 1 then
        vim.cmd("edit " .. last_file)
    else
        vim.notify("Previous file not found: " .. last_file, vim.log.levels.WARN)
    end
end

-- Define commands
vim.api.nvim_create_user_command("FollowMarkdownLink", function()
    M.follow_link()
end, {
    desc = "Follow markdown link under cursor",
})

vim.api.nvim_create_user_command("MarkdownGoBack", function()
    M.go_back()
end, {
    desc = "Go back to previous markdown file",
})

return M
