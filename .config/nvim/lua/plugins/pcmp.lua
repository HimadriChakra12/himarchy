-- ~/.config/nvim/lua/plugins/pcmp.lua
local M = {}
local api = vim.api

-- Plugin state
local state = {
    enabled = true,
    words = {},
    matches = {},
    current_index = 1,
    popup = nil,
    last_input = ""
}

-- Get current theme colors
local function get_theme_colors()
    local colors = {
        bg = vim.fn.synIDattr(vim.fn.synIDtrans(vim.fn.hlID("Normal")), "bg#"),
        fg = vim.fn.synIDattr(vim.fn.synIDtrans(vim.fn.hlID("Normal")), "fg#"),
        selection = vim.fn.synIDattr(vim.fn.synIDtrans(vim.fn.hlID("PmenuSel")), "bg#"),
        match = "#FFD700" -- Gold for matches
    }

    -- Fallback colors
    if colors.bg == "" then colors.bg = "#1e1e2e" end
    if colors.fg == "" then colors.fg = "#cdd6f4" end
    if colors.border == "" then colors.border = "#7f849c" end
    if colors.selection == "" then colors.selection = "#45475a" end

    return colors
end

-- Close the popup if it exists
local function close_popup()
    if state.popup and api.nvim_win_is_valid(state.popup.win_id) then
        api.nvim_win_close(state.popup.win_id, true)
        if api.nvim_buf_is_valid(state.popup.buf_id) then
            api.nvim_buf_delete(state.popup.buf_id, {force = true})
        end
    end
    state.popup = nil
end

-- Show suggestions in a themed popup
local function show_popup()
    close_popup()
    
    if #state.matches == 0 then return end
    
    local colors = get_theme_colors()
    local cursor_pos = api.nvim_win_get_cursor(0)
    local line = cursor_pos[1]
    local col = cursor_pos[2]
    
    -- Create temporary buffer
    local buf = api.nvim_create_buf(false, true)
    api.nvim_buf_set_option(buf, 'buftype', 'nofile')
    api.nvim_buf_set_option(buf, 'swapfile', false)
    api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')
    api.nvim_buf_set_lines(buf, 0, -1, false, state.matches)
    
    -- Calculate popup size
    local max_len = 0
    for _, item in ipairs(state.matches) do
        max_len = math.max(max_len, #item + 2)
    end
    local width = math.min(max_len + 2, math.floor(vim.o.columns * 0.5))
    local height = math.min(#state.matches, 10)
    
    -- Create popup window
    local win = api.nvim_open_win(buf, false, {
        relative = 'cursor',
        row = 1,
        col = 0,
        width = width,
        height = height,
        style = 'minimal',
        noautocmd = true
    })
    
    -- Set highlight groups
    api.nvim_set_hl(0, 'PcmpNormal', { bg = colors.bg, fg = colors.fg })
    api.nvim_set_hl(0, 'PcmpBorder', { fg = colors.border })
    api.nvim_set_hl(0, 'PcmpSelection', { bg = colors.selection })
    api.nvim_set_hl(0, 'PcmpMatch', { fg = colors.match, bold = true })
    
    api.nvim_win_set_option(win, 'winhl', 
        'Normal:PcmpNormal,'..
        'FloatBorder:PcmpBorder,'..
        'CursorLine:PcmpSelection')
    
    -- Highlight first item
    api.nvim_buf_add_highlight(buf, -1, 'PcmpSelection', 0, 0, -1)
    
    -- Highlight matches
    if state.last_input and #state.last_input > 0 then
        for i, match in ipairs(state.matches) do
            local start_pos = match:lower():find(state.last_input:lower(), 1, true)
            if start_pos then
                api.nvim_buf_add_highlight(
                    buf, -1, 'PcmpMatch', 
                    i-1, start_pos-1, start_pos+#state.last_input-1
                )
            end
        end
    end
    
    state.popup = {
        win_id = win,
        buf_id = buf
    }
end

-- Collect words from current buffer
local function collect_words()
    local words = {}
    local seen = {}
    local lines = api.nvim_buf_get_lines(0, 0, -1, false)
    
    for _, line in ipairs(lines) do
        for word in line:gmatch('[%w_]+') do
            if #word > 3 and not seen[word] then
                table.insert(words, word)
                seen[word] = true
            end
        end
    end
    
    state.words = words
end

-- Find matching words
local function find_matches(input)
    if #input < 2 then return {} end
    
    local matches = {}
    local input_lower = input:lower()
    
    for _, word in ipairs(state.words) do
        local word_lower = word:lower()
        if word_lower:find(input_lower, 1, true) then
            table.insert(matches, word)
        end
    end
    
    return matches
end

-- Complete current suggestion
local function complete()
    if not state.popup or #state.matches == 0 then return end
    
    local selected = state.matches[state.current_index]
    local line, col = unpack(api.nvim_win_get_cursor(0))
    local line_text = api.nvim_get_current_line()
    local partial = line_text:sub(1, col):match('[%w_]+$') or ""
    
    vim.schedule(function()
        local new_line = line_text:sub(1, col - #partial) .. selected .. line_text:sub(col + 1)
        api.nvim_set_current_line(new_line)
        api.nvim_win_set_cursor(0, {line, col - #partial + #selected})
        close_popup()
    end)
end

-- Skip to next suggestion
local function skip()
    if not state.popup or #state.matches == 0 then return end
    
    state.current_index = state.current_index % #state.matches + 1
    api.nvim_buf_clear_namespace(state.popup.buf_id, -1, 0, -1)
    api.nvim_buf_add_highlight(state.popup.buf_id, -1, 'PcmpSelection', state.current_index - 1, 0, -1)
end

-- Handle text changes
local function on_text_changed()
    if not state.enabled then return end
    
    local line, col = unpack(api.nvim_win_get_cursor(0))
    local line_text = api.nvim_get_current_line()
    local partial = line_text:sub(1, col):match('[%w_]+$') or ""
    
    if partial == state.last_input then return end
    state.last_input = partial
    
    if #partial < 2 then
        close_popup()
        return
    end
    
    state.matches = find_matches(partial)
    state.current_index = 1
    
    if #state.matches > 0 then
        show_popup()
    else
        close_popup()
    end
end

-- Setup the plugin
function M.setup()
    local colors = get_theme_colors()
    api.nvim_set_hl(0, 'PcmpNormal', { bg = colors.bg, fg = colors.fg })
    api.nvim_set_hl(0, 'PcmpBorder', { fg = colors.border })
    api.nvim_set_hl(0, 'PcmpSelection', { bg = colors.selection })
    api.nvim_set_hl(0, 'PcmpMatch', { fg = colors.match, bold = true })
    
    api.nvim_create_autocmd({'BufEnter', 'BufWritePost'}, {
        callback = collect_words
    })
    
    api.nvim_create_autocmd('TextChangedI', {
        callback = on_text_changed
    })
    
    api.nvim_create_autocmd('InsertLeave', {
        callback = close_popup
    })
    
    vim.keymap.set('i', '<Tab>', function()
        if state.popup then
            complete()
            return ''
        end
        return '<Tab>'
    end, {expr = true})
    
    vim.keymap.set('i', '<S-Tab>', function()
        if state.popup then
            skip()
            return ''
        end
        return '<S-Tab>'
    end, {expr = true})
end

return M
