local M = {}

pin_file = vim.fn.stdpath("config") .. "/pin.json"

local function load_pins()
  local f = io.open(pin_file, "r")
  if not f then return {} end
  local content = f:read("*a")
  f:close()
  local ok, data = pcall(vim.json.decode, content)
  return ok and data or {}
end

local function save_pins(pins)
  local f = io.open(pin_file, "w")
  if f then
    f:write(vim.json.encode(pins))
    f:close()
  end
end

vim.api.nvim_create_user_command("Pin", function(opts)
  local pins = load_pins()
  local key = nil
  local path = nil

  if opts.fargs[1] and #opts.fargs[1] == 1 then
    key = opts.fargs[1]
    path = opts.fargs[2] or vim.fn.expand("%:p")
  else
    path = opts.fargs[1] or vim.fn.expand("%:p")
  end

  if vim.fn.filereadable(path) == 0 then
    print("File not readable: " .. path)
    return
  end

  if not key then
    for i = 97, 122 do
      local ch = vim.fn.nr2char(i)
      local exists = false
      for _, pin in ipairs(pins) do
        if pin.key == ch then exists = true break end
      end
      if not exists then key = ch break end
    end
    if not key then
      print("No available keys (max 26 pins)")
      return
    end
  end

  for _, pin in ipairs(pins) do
    if pin.key == key then
      print("Pin key '" .. key .. "' already in use.")
      return
    end
  end

  table.insert(pins, {
    key = key,
    label = vim.fn.fnamemodify(path, ":t"),
    path = path,
    color = "DashboardLuaFile"
  })
  save_pins(pins)
  print("Pinned [" .. key .. "] " .. path)
end, {
  nargs = "*",
  desc = "Pin current or given file with optional key",
})

vim.api.nvim_create_user_command("Unpin", function(opts)
  local pins = load_pins()
  local key = opts.args
  if key == "" then
    print("Usage: :Unpin <key>")
    return
  end

  local new_pins = {}
  local found = false
  for _, pin in ipairs(pins) do
    if pin.key ~= key then
      table.insert(new_pins, pin)
    else
      found = true
    end
  end

  if found then
    save_pins(new_pins)
    print("Unpinned item with key: " .. key)
  else
    print("No pinned file with key: " .. key)
  end
end, {
  nargs = 1,
  desc = "Unpin a file by its key (e.g., :Unpin a)",
})

function M.show_dashboard()
  -- Optional: put your dashboard code here or leave empty if handled elsewhere
end

vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    vim.schedule(M.show_dashboard)
  end,
  nested = true,
  desc = "Show custom dashboard"
})

vim.api.nvim_create_user_command("Dashboard", M.show_dashboard, {})

function M.get_pins()
  return load_pins()
end

return M
