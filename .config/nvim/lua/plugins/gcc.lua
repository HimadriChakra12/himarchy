local function is_gcc_compatible()
    local ext = vim.fn.expand("%:e") -- File extension
    local gcc_extensions = {
        c = true,
        cpp = true,
        cc = true,
        cxx = true,
    }
    return gcc_extensions[ext] ~= nil
end

local function final_command()
    local ext = vim.fn.expand("%:e")

    local input = vim.fn.expand("%:p")     -- Full path to file.c or file.cpp
    local output = vim.fn.expand("%:p:r")  -- Full path without extension
    local exe_output = output .. ".exe"

    local compiler
    if ext == "c" then
        compiler = "gcc"
    elseif ext == "cpp" or ext == "cc" or ext == "cxx" then
        compiler = "g++"
    else
        return nil
    end

    -- Final command: compile then run
    return compiler .. ' -o "' .. exe_output .. '" "' .. input .. '" ; "' .. exe_output .. '"'
end

local function gcc()
    if not is_gcc_compatible() then
        vim.notify("This file type is not supported for gcc/g++ compilation.", vim.log.levels.ERROR)
        return
    end

    local cmd = final_command()
    if not cmd then
        vim.notify("Failed to generate gcc command.", vim.log.levels.ERROR)
        return
    end

    -- Save current window height
    local win_height = vim.api.nvim_win_get_height(0)
    local terminal_height = math.floor(win_height / 5)

    -- Open a horizontal split at the bottom with terminal
    vim.cmd(terminal_height .. "split | terminal")

    -- Get the terminal job id
    local bufnr = vim.api.nvim_get_current_buf()
    local job_id = vim.b[bufnr].terminal_job_id

    -- Send the gcc command
    vim.fn.chansend(job_id, cmd .. "\n")

    -- Move focus back to the top window (your code)
    vim.cmd("wincmd k")
end

vim.keymap.set("n", "<leader>cc", gcc, { desc = "Compile current C/C++ file with gcc/g++" })

