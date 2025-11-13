vim.api.nvim_create_autocmd("BufEnter", {
    pattern = "*",
    callback = function()
        if vim.bo.filetype == "" then
local function display_startup()
  local lines = {
    "",
}
--νλιμ [u] New File   [h] Help   [q] Quit
  for _, line in ipairs(lines) do
    vim.api.nvim_echo({{line, ""}}, true, {})
  end
end


vim.api.nvim_create_autocmd("VimEnter", {
  pattern = "*",
  callback = display_startup
})

-- 
vim.opt.shortmess:append("I")
        else
            vim.opt.number = false
            vim.opt.relativenumber = true
        end
    end,
})

local function show_dashboard()
    if vim.fn.argc() == 0 and vim.fn.line2byte('$') == -1 then
        -- Clear default intro silently

        -- Define color highlight groups
        vim.cmd([[
        highlight! DashboardHeader guifg=#b8bb26 ctermfg=75
        ]])

        -- Dashboard header
        local header = {
            "",
            "",
            "   ██    ███   ████",
            "   ██   ████     ████    █████     ██   ████",
            "   ██  ██ ██      ███     ██       ██   ██",
            "   ████   ██   ████  ██   ██  ████ ██   ██",
            "   ██     ██  ██     ███  █████    ██   ██",
            "          ███                      █████",
            "           ████  ███████████████   ██",
            "                                   ██",
            "",
            "                  Neovim " .. vim.version().major .. "." .. vim.version().minor,
            "",
            "",
            "",

        }

        local pinner = require("himadri.pin")
        local pins = pinner.get_pins()

        -- Prepare pins display lines
        local pin_lines = { "  Pinned" }
        if #pins == 0 then
            table.insert(pin_lines, "  No files pinned.")
        else
            for i, pin in ipairs(pins) do
                table.insert(pin_lines, string.format("  %s. [%s]", pin.key, vim.fn.fnamemodify(pin.path, ":~")))
            end
        end
        local function get_pinned_files()
            local config_path = vim.fn.stdpath("config")
            local pin_path = config_path .. "/pins.json"
            local pins = {}

            -- Load pins.json if it exists
            if vim.fn.filereadable(pin_path) == 1 then
                local content = vim.fn.readfile(pin_path)
                pins = vim.fn.json_decode(table.concat(content, "\n")) or {}
            end

            -- Always include init.lua and pins.json
            local always_pinned = {
                config_path .. "/init.lua",
                pin_path,
            }

            for _, file in ipairs(always_pinned) do
                if not vim.tbl_contains(pins, file) then
                    table.insert(pins, file)
                end
            end

            return pins
        end


        -- Get recent files (last 10 accessible files)
        local recent_files = {}
        local oldfiles = vim.v.oldfiles
        local counter = 1
        for i = 1, #oldfiles do
            if counter > 9 then break end
            local file = oldfiles[i]
            if vim.fn.filereadable(file) == 1 then
                local ext = file:match("^.+(%..+)$") or ""
                local color_group = "DashboardLuaFile" -- default

                if ext == ".py" then color_group = "DashboardPythonFile"
                elseif ext == ".md" or ext == ".txt" then color_group = "DashboardTextFile"
                elseif ext == ".json" or ext == ".yaml" or ext == ".yml" then color_group = "DashboardConfigFile"
                elseif ext == ".c" or ext == ".cpp" or ext == ".cs" then color_group = "DashboardCFile"
                elseif ext == ".ps1" then color_group = "DashboardPsFile"
                end

                table.insert(recent_files, {
                    text = string.format("  %d. [%s]", counter, file),
                    color = color_group,
                    path = file
                })
                counter = counter + 1
            end
        end



        -- Footer with commands
        local footer = {
            "",
            "  [n] New File",
            "  [h] Help",
            "  [q] Quit",
            "  [o],[Enter] Open the file.",
            "",
        }

        -- Create buffer
        local buf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_name(buf, "Welcome, Himadri")
        vim.api.nvim_buf_set_option(buf, 'buftype', 'nofile')
        vim.api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')
        vim.api.nvim_buf_set_option(buf, 'swapfile', false)
        vim.api.nvim_buf_set_option(buf, 'filetype', 'Sayo')
        vim.api.nvim_buf_set_option(buf, 'number', false) -- Turn off line numbers
        vim.api.nvim_buf_set_option(buf, 'relativenumber', false) -- Turn off relative numbers

        -- Build content
        local content = vim.list_extend({}, header)
        vim.list_extend(content, pin_lines) 
        table.insert(content, "")
        table.insert(content, "  Recent:")

        for _, item in ipairs(recent_files) do
            table.insert(content, item.text)
        end

        vim.list_extend(content, footer)

        -- Set content and highlights
        vim.api.nvim_buf_set_option(buf, 'modifiable', true)
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, content)

        -- Header highlights
        for i = 3, 8 do  -- ASCII art lines
            vim.api.nvim_buf_add_highlight(buf, -1, 'DashboardHeader', i-1, 0, -1)
        end

        -- Recent files highlights
        local line_num = #header + 3
        for _, item in ipairs(recent_files) do
            vim.api.nvim_buf_add_highlight(buf, -1, item.color, line_num, 0, 0)
            line_num = line_num + 1
        end

        vim.api.nvim_buf_set_option(buf, 'modifiable', false)

        -- Display buffer
        vim.api.nvim_set_current_buf(buf)
        vim.api.nvim_win_set_cursor(0, {21, 6})  -- Position cursor at line 14, column 7

        -- Key mappings
        local opts = { buffer = buf, silent = true, nowait = true }

        -- Number keys 1-9 to open recent files
        for i, item in ipairs(recent_files) do
            if i <= 9 then
                vim.keymap.set('n', tostring(i), function()
                    vim.cmd('edit ' .. vim.fn.fnameescape(item.path))
                end, opts)
            end
        end

        -- gf to open file under cursor
        --vim.keymap.set('n', 'o', function()
            --local line = vim.api.nvim_get_current_line()
            --local path = line:match('%[(.*)%]')
            --if path and vim.fn.filereadable(path) == 1 then
                --vim.cmd('edit ' .. vim.fn.fnameescape(path))
            --end
        --end, opts)
        --vim.keymap.set('n', '<Enter>', function()
            --local line = vim.api.nvim_get_current_line()
            --local path = line:match('%[(.*)%]')
            --if path and vim.fn.filereadable(path) == 1 then
                --vim.cmd('edit ' .. vim.fn.fnameescape(path))
            --end
        --end, opts)

        vim.api.nvim_buf_set_option(buf, "number", false)
        vim.api.nvim_buf_set_option(buf, "relativenumber", false)
        vim.keymap.set('n', 'n', ':enew<CR>', opts)
        vim.keymap.set('n', 'e', ':edit $MYVIMRC<CR>', opts)
        vim.keymap.set('n', 'h', ':help<CR>', opts)
        vim.keymap.set('n', 'q', ':q<CR>', opts)
        vim.keymap.set("n", "<CR>", function()
            local line = vim.api.nvim_get_current_line()

            -- Try to match a pin first
            local pin_key = line:match("^%s*([%a])%. ")
            if pin_key then
                for _, pin in ipairs(pins) do
                    if pin.key == pin_key then
                        vim.cmd("edit " .. vim.fn.fnameescape(pin.path))
                        return
                    end
                end
            end

            -- Fallback: match any [path] pattern (for recent files)
            local path = line:match('%[(.*)%]')
            if path and vim.fn.filereadable(path) == 1 then
                vim.cmd("edit " .. vim.fn.fnameescape(path))
            end
        end, opts)

        vim.keymap.set("n", 'o', function()
            local line = vim.api.nvim_get_current_line()

            -- Try to match a pin first
            local pin_key = line:match("^%s*([%a])%. ")
            if pin_key then
                for _, pin in ipairs(pins) do
                    if pin.key == pin_key then
                        vim.cmd("edit " .. vim.fn.fnameescape(pin.path))
                        return
                    end
                end
            end

            -- Fallback: match any [path] pattern (for recent files)
            local path = line:match('%[(.*)%]')
            if path and vim.fn.filereadable(path) == 1 then
                vim.cmd("edit " .. vim.fn.fnameescape(path))
            end
        end, opts)

    end
end

-- Set up autocommand
vim.api.nvim_create_autocmd("VimEnter", {
    callback = function()
        vim.schedule(show_dashboard)
    end,
    nested = true,
    desc = "Show custom dashboard when no file specified"
})

-- Add command to manually open dashboard
vim.api.nvim_create_user_command("Dashboard", show_dashboard, {})
