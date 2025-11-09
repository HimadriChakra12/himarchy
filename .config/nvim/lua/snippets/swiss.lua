-- File: ~/.config/nvim/lua/swiss.lua
local M = {}

local function expand_swiss()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local row = cursor[1] - 1
  local col = cursor[2]
  local line = vim.api.nvim_get_current_line()
  local before = line:sub(1, col)
  local after = line:sub(col + 2)

  -- Match swiss>
  local expr = before:match("(swiss)$")
  if not expr then return ">" end

  vim.schedule(function()
    local template = {
      "{",
      '  "name": "pkgname",',
      '  "id": "pkgid",',
      '  "version": "1.0.0",',
      '  "url": "https://example.com/file.exe",',
      '  "type": "exe",',
      '  "installer": "nsis",',
      '  "silent": "/S",',
      '  "uninstaller": "C:\\\\Program Files\\\\pkg\\\\unins000.exe",',
      '  "untype": "nsis"',
      "}",
    }

    -- Replace the line with the template
    vim.api.nvim_buf_set_lines(0, row, row + 1, false, template)

    -- Put cursor inside "name"
    vim.api.nvim_win_set_cursor(0, { row + 1, 10 })
  end)

  return ""
end

function M.setup()
  vim.api.nvim_create_autocmd("FileType", {
    pattern = "json",
    callback = function()
      vim.keymap.set("i", ">", function()
        return expand_swiss()
      end, { buffer = true, expr = true, desc = "Expand swiss> into JSON template" })
    end,
  })
end

return M
