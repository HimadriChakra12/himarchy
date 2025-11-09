-- File: lua/netrw-popup.lua
local M = {}

local popup_winid = nil
local original_cwd = nil

function M.toggle_netrw_popup()
    if popup_winid and vim.api.nvim_win_is_valid(popup_winid) then
        -- Close the existing popup
        vim.api.nvim_win_close(popup_winid, true)
        popup_winid = nil
        -- Restore original working directory if it was changed
        if original_cwd then
            vim.cmd('cd ' .. vim.fn.fnameescape(original_cwd))
            original_cwd = nil
        end
        return
    end

    -- Save original working directory
    original_cwd = vim.fn.getcwd()

    -- Create a temporary buffer
    local buf = vim.api.nvim_create_buf(false, true)

    -- Set up Netrw in the buffer
    vim.api.nvim_buf_set_option(buf, 'buftype', 'nofile')
    vim.api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')
    vim.api.nvim_buf_set_option(buf, 'swapfile', false)

    -- Calculate dimensions (60% of current window)
    local width = math.floor(vim.o.columns * 0.6)
    local height = math.floor(vim.o.lines * 0.6)
    local col = math.floor((vim.o.columns - width) / 2)
    local row = math.floor((vim.o.lines - height) / 2)

    -- Create the popup window
    popup_winid = vim.api.nvim_open_win(buf, true, {
        relative = 'editor',
        width = width,
        height = height,
        col = col,
        row = row,
        style = 'minimal',
        border = 'rounded'
    })

    -- Open Netrw in the popup
    vim.cmd('edit .')

    -- Set up autocommands to clean up when the popup is closed
    vim.api.nvim_create_autocmd('WinClosed', {
        buffer = buf,
        callback = function()
            if popup_winid and vim.api.nvim_win_is_valid(popup_winid) then
                vim.api.nvim_win_close(popup_winid, true)
            end
            popup_winid = nil
            if original_cwd then
                vim.cmd('cd ' .. vim.fn.fnameescape(original_cwd))
                original_cwd = nil
            end
        end,
        once = true
    })

    -- Set keymaps for easier navigation
    vim.api.nvim_buf_set_keymap(buf, 'n', 'q', '<cmd>lua require("netrw-popup").toggle_netrw_popup()<CR>', {noremap = true, silent = true})
    vim.api.nvim_buf_set_keymap(buf, 'n', '<Esc>', '<cmd>lua require("netrw-popup").toggle_netrw_popup()<CR>', {noremap = true, silent = true})
end

return M
