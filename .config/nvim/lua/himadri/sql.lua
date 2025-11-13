local M = {}
local sqlite = require("sqlite")

-- Database path
local db_path = vim.fn.stdpath("data") .. "/my_database.db"
local db = sqlite.open(db_path)

-- Track preview buffer and executed non-selects
local preview_buf = nil
local executed_cache = {}

-- Split SQL text into statements by semicolon
local function split_sql(sql_text)
  local statements = {}
  for stmt in sql_text:gmatch("([^;]+);") do
    stmt = stmt:gsub("^%s*(.-)%s*$", "%1") -- trim
    if stmt ~= "" then
      table.insert(statements, stmt)
    end
  end
  return statements
end

-- Extract columns from SELECT statement
local function parse_columns(select_stmt)
  local cols = select_stmt:match("select%s+(.-)%s+from")
  if not cols then return nil end
  local columns = {}
  for col in cols:gmatch("[^,]+") do
    col = col:gsub("^%s*(.-)%s*$", "%1")
    table.insert(columns, col)
  end
  return columns
end

-- Execute a statement safely
local function execute_stmt(stmt)
  local lines = {}
  local lower = stmt:lower()

  if lower:match("^select") then
    local columns = parse_columns(stmt)
    local ok, result = pcall(function() return db:eval(stmt) end)
    if not ok then
      return { "SQLite SELECT error: " .. result }
    elseif type(result) ~= "table" or #result == 0 then
      return { "No results" }
    else
      if columns then
        table.insert(lines, table.concat(columns, " | "))
        for _, row in ipairs(result) do
          local parts = {}
          for _, col in ipairs(columns) do
            table.insert(parts, tostring(row[col]))
          end
          table.insert(lines, table.concat(parts, " | "))
        end
      else
        local headers = vim.tbl_keys(result[1])
        table.insert(lines, table.concat(headers, " | "))
        for _, row in ipairs(result) do
          local parts = {}
          for _, key in ipairs(headers) do
            table.insert(parts, tostring(row[key]))
          end
          table.insert(lines, table.concat(parts, " | "))
        end
      end
    end
  else
    if executed_cache[stmt] then return {} end
    executed_cache[stmt] = true
    local ok, res = pcall(function() return db:eval(stmt) end)
    if not ok then
      return { "SQLite error: " .. res }
    else
      return { "Executed once: " .. stmt }
    end
  end

  return lines
end

-- Preview SQL from current buffer
function M.preview()
  local buf_sql = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local sql_text = table.concat(buf_sql, " ")
  local statements = split_sql(sql_text)

  local result_lines = {}

  for _, stmt in ipairs(statements) do
    local stmt_lower = stmt:lower()
    if stmt_lower:match("^select") then
      local res = execute_stmt(stmt)
      for _, line in ipairs(res) do
        table.insert(result_lines, line)
      end
      table.insert(result_lines, "") -- empty line between multiple SELECTs
    else
      execute_stmt(stmt)
    end
  end

  if preview_buf and vim.api.nvim_buf_is_valid(preview_buf) then
    vim.api.nvim_buf_set_option(preview_buf, "modifiable", true)
    vim.api.nvim_buf_set_lines(preview_buf, 0, -1, false, result_lines)
    vim.api.nvim_buf_set_option(preview_buf, "modifiable", false)
  else
    vim.cmd("10split")
    preview_buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_win_set_buf(0, preview_buf)
    vim.api.nvim_buf_set_lines(preview_buf, 0, -1, false, result_lines)
    vim.api.nvim_buf_set_option(preview_buf, "modifiable", false)
    vim.api.nvim_buf_set_option(preview_buf, "bufhidden", "wipe")
    vim.api.nvim_win_set_option(0, "wrap", false)
  end
end

-- Close DB on exit
vim.api.nvim_create_autocmd("VimLeavePre", {
  callback = function()
    db:close()
  end,
})

return M
