-- Path to your dx.exe, adjust if needed
local dx_path = "C:\\farm\\wheats\\dx\\dx.exe"

-- Run a background command
vim.api.nvim_create_user_command("DxRun", function(opts)
  local cmd = table.concat(opts.fargs, " ")
  vim.fn.jobstart({dx_path, unpack(opts.fargs)}, {detach = true})
  print("[Dx] Started command: " .. cmd)
end, {nargs = "+"})

-- List background processes
vim.api.nvim_create_user_command("DxList", function()
  vim.fn.jobstart({dx_path, "list"}, {
    on_stdout = function(_, data)
      if data then
        for _, line in ipairs(data) do
          if line ~= "" then print(line) end
        end
      end
    end,
    stdout_buffered = true
  })
end, {})

-- Kill a process by ID
vim.api.nvim_create_user_command("DxKill", function(opts)
  vim.fn.jobstart({dx_path, "kill", opts.args}, {detach = true})
  print("[Dx] Killing process ID: " .. opts.args)
end, {nargs = 1})

-- Show logs of a process by ID
vim.api.nvim_create_user_command("DxLogs", function(opts)
  vim.fn.jobstart({dx_path, "logs", opts.args}, {
    on_stdout = function(_, data)
      if data then
        for _, line in ipairs(data) do
          if line ~= "" then print(line) end
        end
      end
    end,
    stdout_buffered = true
  })
end, {nargs = 1})

