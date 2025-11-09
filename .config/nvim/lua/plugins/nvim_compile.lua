-- Minimal compile mode for Neovim with error line highlighting and navigation.

local M = {}

local compile_history = {}
local MAX_HISTORY = 20

local compile_output_buf_id = nil
local compile_output_win_id = nil
local original_editing_win_id = nil

local function add_to_history(command)
    if #compile_history == 0 or compile_history[1] ~= command then
        table.insert(compile_history, 1, command)
        if #compile_history > MAX_HISTORY then
            table.remove(compile_history)
        end
    end
end

local function is_cmake_project()
    return vim.fn.filereadable("CMakeLists.txt") == 1
end

local function get_user_command()
    local prompt = "[Compile] Enter command: "
    return vim.fn.input(prompt, "", "custom,v:lua.require'nvim_compile'.get_completions")
end

local function jump_to_error(error_entry)
    if not error_entry then return end

    local filepath = error_entry.filename
    local target_lnum = error_entry.lnum
    local target_col = error_entry.col

    if vim.fn.filereadable(filepath) == 0 then
        local cwd = vim.fn.getcwd()
        local new_filepath = cwd .. "/" .. filepath
        if vim.fn.has("win32") == 1 then
            new_filepath = new_filepath:gsub("/", "\\")
        end
        if vim.fn.filereadable(new_filepath) == 1 then
            filepath = new_filepath
        else
            vim.api.nvim_echo({ { "File not found: " .. filepath, "ErrorMsg" } }, false, {})
            return
        end
    end

    local target_buf_id = vim.fn.bufnr(filepath)
    if target_buf_id == -1 then
        target_buf_id = vim.fn.bufadd(filepath)
        if target_buf_id == -1 then
            vim.api.nvim_echo({ { "Could not create buffer for: " .. filepath, "ErrorMsg" } }, false, {})
            return
        end
    end

    if not original_editing_win_id or not vim.api.nvim_win_is_valid(original_editing_win_id) then
        vim.api.nvim_echo({ { "Original editing window not found or invalid. Cannot jump to error.", "ErrorMsg" } },
            false, {})
        return
    end

    vim.api.nvim_win_set_buf(original_editing_win_id, target_buf_id)
    vim.api.nvim_set_current_win(original_editing_win_id)

    vim.api.nvim_win_set_cursor(0, { target_lnum, target_col - 1 })
    vim.cmd("normal! zz")
    vim.cmd("normal! ^")
end

local function parse_error_line(buf_id, line_num)
    local line = vim.api.nvim_buf_get_lines(buf_id, line_num - 1, line_num, false)[1]
    if not line then return nil end

    local patterns = {
        "([^:]+):(%d+):(%d+):%s*(error|warning):%s*(.*)",
        "([^:]+):(%d+):%s*(error|warning):%s*(.*)",
        "([^:]+):(%d+)%.%d+%-(%d+)%.%d+:%s*(error|warning):%s*(.*)",
        "([^%(]+)%((%d+)%)%s*:%s*(error|warning):%s*(.*)",
        "([^:]+):(%d+):%s*(.*)",
    }

    for _, pattern in ipairs(patterns) do
        local file, line_num_str, col_num_str, type_str, text
        if pattern == "([^:]+):(%d+):(%d+):%s*(error|warning):%s*(.*)" then
            file, line_num_str, col_num_str, type_str, text = line:match(pattern)
        elseif pattern == "([^:]+):(%d+):%s*(error|warning):%s*(.*)" then
            file, line_num_str, type_str, text = line:match(pattern)
            col_num_str = "1"
        elseif pattern == "([^:]+):(%d+)%.%d+%-(%d+)%.%d+:%s*(error|warning):%s*(.*)" then
            local sl, sc, el, ec
            file, sl, sc, el, ec, type_str, text = line:match(pattern)
            line_num_str = sl
            col_num_str = sc or "1"
        elseif pattern == "([^%(]+)%((%d+)%)%s*:%s*(error|warning):%s*(.*)" then
            file, line_num_str, type_str, text = line:match(pattern)
            col_num_str = "1"
        elseif pattern == "([^:]+):(%d+):%s*(.*)" then
            file, line_num_str, text = line:match(pattern)
            col_num_str = "1"
            type_str = "E"
        end


        if file then
            return {
                filename = file,
                lnum = tonumber(line_num_str),
                col = tonumber(col_num_str) or 1,
                type = type_str and type_str:sub(1, 1):upper() or "E",
                text = text,
            }
        end
    end
    return nil
end

local function setup_compile_buffer_keymaps(buf_id)
    local opts = { buffer = buf_id, noremap = true, silent = true }
    vim.keymap.set('n', '<CR>', function()
        local cursor_pos = vim.api.nvim_win_get_cursor(0)
        local line_num = cursor_pos[1]
        local error_entry = parse_error_line(buf_id, line_num)
        if error_entry then
            jump_to_error(error_entry)
        else
            local next_error_line = vim.api.nvim_buf_get_var(buf_id, "next_error_line") or 0
            local current_line_idx = line_num - 1

            local extmarks = vim.api.nvim_buf_get_extmarks(buf_id, vim.api.nvim_create_namespace("compile_errors"),
                { current_line_idx, 0 }, -1, { details = true })

            local found_next = false
            for _, mark in ipairs(extmarks) do
                local mark_row = mark[1]
                local mark_details = mark[3]
                if mark_row > current_line_idx then
                    vim.api.nvim_win_set_cursor(0, { mark_row + 1, 0 })
                    vim.cmd("normal! zz")
                    found_next = true
                    break
                end
            end

            if not found_next then
                vim.api.nvim_echo({ { "No more errors/warnings found below.", "WarningMsg" } }, false, {})
            end
        end
    end, opts)

    vim.keymap.set('n', 'p', function()
        local cursor_pos = vim.api.nvim_win_get_cursor(0)
        local current_line_idx = cursor_pos[1] - 1

        local extmarks = vim.api.nvim_buf_get_extmarks(buf_id, vim.api.nvim_create_namespace("compile_errors"), { 0, 0 },
            { current_line_idx, 0 }, { details = true, limit = 1000 })

        local prev_mark_row = -1
        for i = #extmarks, 1, -1 do
            local mark = extmarks[i]
            local mark_row = mark[1]
            if mark_row < current_line_idx then
                prev_mark_row = mark_row
                break
            end
        end

        if prev_mark_row ~= -1 then
            vim.api.nvim_win_set_cursor(0, { prev_mark_row + 1, 0 })
            vim.cmd("normal! zz")
        else
            vim.api.nvim_echo({ { "No previous errors/warnings found.", "WarningMsg" } }, false, {})
        end
    end, opts)
end


local function highlight_errors(output, output_buf, elapsed_time, filename, command_executed, time_unit)
    local first_error = nil
    local error_count = 0
    local warning_count = 0
    local ns_id = vim.api.nvim_create_namespace("compile_errors")
    vim.api.nvim_buf_clear_namespace(output_buf, ns_id, 0, -1)

    vim.api.nvim_buf_set_option(output_buf, "modifiable", true)
    vim.api.nvim_buf_set_option(output_buf, "readonly", false)

    local lines_to_set = {}

    local raw_output_lines = {}
    for line in output:gmatch("([^\n]+)") do
        table.insert(raw_output_lines, line)
    end
    for _, line in ipairs(raw_output_lines) do
        table.insert(lines_to_set, line)
    end

    table.insert(lines_to_set, "")
    table.insert(lines_to_set, "--------------------------------------------------------------------------------")
    table.insert(lines_to_set, "")

    local actual_compiler_command = nil
    for _, line in ipairs(raw_output_lines) do
        if line:match("^%s*%S") then
            actual_compiler_command = line
            break
        end
    end
    if actual_compiler_command then
        table.insert(lines_to_set, "--- Actual Command: " .. actual_compiler_command .. " ---")
    end

    table.insert(lines_to_set, "--- User Command: " .. command_executed .. " ---")

    local temp_line_number = 0
    for line in output:gmatch("([^\n]+)") do
        temp_line_number = temp_line_number + 1
        local error_entry = parse_error_line(output_buf, temp_line_number)
        if error_entry then
            if not first_error then
                first_error = error_entry
            end
            if error_entry.type == "E" then
                error_count = error_count + 1
            else
                warning_count = warning_count + 1
            end
        end
    end

    if first_error then
        local first_error_msg = string.format("--- First Error: %s:%d:%d: %s: %s ---",
            first_error.filename, first_error.lnum, first_error.col,
            first_error.type == "E" and "error" or "warning",
            first_error.text)
        table.insert(lines_to_set, first_error_msg)

        local summary = string.format("--- Summary: Found %d error(s) and %d warning(s). ---",
            error_count, warning_count)
        table.insert(lines_to_set, summary)
    else
        local success_message = string.format("--- Compilation done! ---")
        local file_info = string.format("--- File: %s ---", filename or "N/A")
        local time_info = string.format("--- Time: %.2f %s ---", elapsed_time, time_unit)

        table.insert(lines_to_set, success_message)
        table.insert(lines_to_set, file_info)
        table.insert(lines_to_set, time_info)
    end

    vim.api.nvim_buf_set_lines(output_buf, 0, -1, false, lines_to_set)

    local current_line_in_buf = 0
    for i, line in ipairs(lines_to_set) do
        current_line_in_buf = current_line_in_buf + 1
        local error_entry = parse_error_line(output_buf, current_line_in_buf)
        if error_entry then
            local hl_group = error_entry.type == "E" and "ErrorMsg" or "WarningMsg"
            vim.api.nvim_buf_add_highlight(output_buf, ns_id, hl_group, current_line_in_buf - 1, 0, -1)
        end

        if line:match("^%-%-%- Actual Command:") then
            vim.api.nvim_buf_add_highlight(output_buf, ns_id, "String", current_line_in_buf - 1, 0, -1)
        elseif line:match("^%-%-%- User Command:") then
            vim.api.nvim_buf_add_highlight(output_buf, ns_id, "Statement", current_line_in_buf - 1, 0, -1)
        elseif line:match("^%-%-%- Compilation done!") then
            vim.api.nvim_buf_add_highlight(output_buf, ns_id, "DiagnosticOk", current_line_in_buf - 1, 0, -1)
        elseif line:match("^%-%-%- File:") then
            vim.api.nvim_buf_add_highlight(output_buf, ns_id, "Comment", current_line_in_buf - 1, 0, -1)
        elseif line:match("^%-%-%- Time:") then
            vim.api.nvim_buf_add_highlight(output_buf, ns_id, "Constant", current_line_in_buf - 1, 0, -1)
        elseif line:match("^%-%-%- First Error:") then
            vim.api.nvim_buf_add_highlight(output_buf, ns_id, "ErrorMsg", current_line_in_buf - 1, 0, -1)
        elseif line:match("^%-%-%- Summary:") then
            vim.api.nvim_buf_add_highlight(output_buf, ns_id, "MoreMsg", current_line_in_buf - 1, 0, -1)
        end
    end

    vim.api.nvim_buf_set_option(output_buf, "modifiable", false)
    vim.api.nvim_buf_set_option(output_buf, "readonly", true)
    vim.api.nvim_win_set_cursor(compile_output_win_id, { 1, 0 })
    vim.cmd("normal! zz")
end

local function execute_compile_command(command)
    if not command or command == "" then return end
    add_to_history(command)

    local original_command = command
    if is_cmake_project() and vim.fn.isdirectory("build") == 1 then
        command = "cd build && " .. command
    end

    local shell_command
    if vim.fn.has("win32") == 1 then
        shell_command = 'cmd.exe /c "' .. command .. ' 2>&1"'
    else
        shell_command = 'sh -c "' .. command .. ' 2>&1"'
    end

    local output_buf
    if compile_output_buf_id and vim.api.nvim_buf_is_valid(compile_output_buf_id) then
        output_buf = compile_output_buf_id
        vim.api.nvim_buf_set_option(output_buf, "modifiable", true)
        vim.api.nvim_buf_set_option(output_buf, "readonly", false)
        vim.api.nvim_buf_set_lines(output_buf, 0, -1, false, {})
    else
        output_buf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_name(output_buf, "[Compile Output]")
        vim.api.nvim_buf_set_option(output_buf, "buftype", "nofile")
        vim.api.nvim_buf_set_option(output_buf, "bufhidden", "wipe")
        vim.api.nvim_buf_set_option(output_buf, "swapfile", false)
        compile_output_buf_id = output_buf
        setup_compile_buffer_keymaps(output_buf)
    end

    local start_time = vim.fn.reltime()
    local full_output = vim.fn.system(shell_command)
    local exit_code = vim.v.shell_error
    local end_time = vim.fn.reltime(start_time)
    local elapsed_time_value = 0.0
    local time_unit = "seconds"

    local explicit_time_parsed = false
    if command:match("^time ") then
        for line in full_output:gmatch("([^\n]+)") do
            local real_time_ms = line:match("Executed in (%d+%.%d+) millis")
            if real_time_ms then
                elapsed_time_value = tonumber(real_time_ms)
                time_unit = "milliseconds"
                explicit_time_parsed = true
                break
            end
            local gnu_time_match = line:match("real%s+(%d+)m(%d+%.%d+)s")
            if gnu_time_match then
                local minutes = tonumber(gnu_time_match[1])
                local seconds = tonumber(gnu_time_match[2])
                elapsed_time_value = (minutes * 60) + seconds
                time_unit = "seconds"
                explicit_time_parsed = true
                break
            end
            local gnu_time_simple_match = line:match("real%s+(%d+%.%d+)s")
            if gnu_time_simple_match then
                elapsed_time_value = tonumber(gnu_time_simple_match)
                time_unit = "seconds"
                explicit_time_parsed = true
                break
            end
        end
    end

    if not explicit_time_parsed then
        if type(end_time) == "table" and #end_time >= 2 then
            elapsed_time_value = (end_time[1] or 0) + ((end_time[2] or 0) / 1e6)
            time_unit = "seconds"
        else
            vim.api.nvim_echo(
            { { "Warning: Could not measure compilation time accurately with reltime.", "WarningMsg" } }, false, {})
            elapsed_time_value = 0.0
            time_unit = "seconds"
        end
    end

    if exit_code ~= 0 and (full_output == nil or full_output == "") then
        vim.api.nvim_echo(
            { { "Failed to run command (exit code " .. exit_code .. "): " .. original_command, "ErrorMsg" } }, false, {})
        return
    end

    local output_lines = {}
    for line in full_output:gmatch("[^\n]+") do
        table.insert(output_lines, line)
    end

    vim.api.nvim_buf_set_option(output_buf, "modifiable", true)
    vim.api.nvim_buf_set_option(output_buf, "readonly", false)
    vim.api.nvim_buf_set_lines(output_buf, 0, -1, false, output_lines)
    vim.api.nvim_buf_set_option(output_buf, "modifiable", false)
    vim.api.nvim_buf_set_option(output_buf, "readonly", true)

    original_editing_win_id = vim.api.nvim_get_current_win()
    local original_filename = vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(original_editing_win_id))
    local filename_only = original_filename:match("([^/\\]+)$") or original_filename

    local output_window_found = false

    if compile_output_win_id and vim.api.nvim_win_is_valid(compile_output_win_id) and
        vim.api.nvim_win_get_buf(compile_output_win_id) == output_buf then
        output_window_found = true
    end

    if output_window_found then
        vim.api.nvim_set_current_win(compile_output_win_id)
        vim.api.nvim_win_set_buf(compile_output_win_id, output_buf)
        vim.cmd("normal! G")
    else
        vim.api.nvim_set_current_win(original_editing_win_id)
        vim.cmd("below new")
        compile_output_win_id = vim.api.nvim_get_current_win()
        vim.api.nvim_win_set_buf(compile_output_win_id, output_buf)
        vim.cmd("normal! G")
        vim.api.nvim_set_current_win(original_editing_win_id)
    end

    highlight_errors(full_output, output_buf, elapsed_time_value, filename_only, original_command, time_unit)
end

function M.get_completions(ArgLead, CmdLine, CursorPos)
    local matches = {}
    for _, cmd in ipairs(compile_history) do
        if ArgLead == "" or cmd:lower():find(ArgLead:lower(), 1, true) then
            table.insert(matches, cmd)
        end
    end
    return matches
end

function M.compile_mode()
    local cmd = get_user_command()
    if cmd and cmd ~= "" then
        execute_compile_command(cmd)
    end
end

vim.api.nvim_create_user_command("CompileMode", function()
    M.compile_mode()
end, {
    desc = "Run a compile command (Emacs-like interactive mode)",
})

vim.api.nvim_create_user_command("Compile", function(args)
    local cmd = table.concat(args.fargs, " ")
    if cmd ~= "" then
        execute_compile_command(cmd)
    else
        vim.api.nvim_echo({ { "Usage: :Compile <command>", "ErrorMsg" } }, false, {})
    end
end, {
    desc = "Run a compile command directly",
    nargs = "+",
    complete = function(ArgLead, CmdLine, CursorPos)
        return M.get_completions(ArgLead, CmdLine, CursorPos)
    end,
})

return M
