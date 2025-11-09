local M = {}

-- Parses a tag expression into tag info
local function parse_part(part)
    local tag = part:match("^[^.#:=]+") or "div"
    local attrs = {}

    -- Handle multiple classes like .a.b.c
    local classes = {}
    for cls in part:gmatch("%.([%w_-]+)") do
        table.insert(classes, cls)
    end
    if #classes > 0 then
        table.insert(attrs, string.format('class="%s"', table.concat(classes, " ")))
    end

    -- Handle ID
    local id = part:match("#([%w_-]+)")
    if id then
        table.insert(attrs, string.format('id="%s"', id))
    end

    -- Repeat count
    local count = tonumber(part:match("=(%d+)")) or 1

    return { tag = tag, attrs = attrs, count = count }
end

local function build_html_with_cursor(parts, index, indent_level)
  indent_level = indent_level or 0
  local part = parse_part(parts[index])
  local attr_str = #part.attrs > 0 and " " .. table.concat(part.attrs, " ") or ""
  local inner_lines = {}
  local cursor_row = 1
  local cursor_col = 0

  local is_one_liner = ({ li = true, span = true, b = true, i = true, strong = true, em = true })[part.tag]

  local has_children = parts[index + 1] ~= nil
  if has_children then
    local result = build_html_with_cursor(parts, index + 1, indent_level + 1)
    inner_lines = result.lines
    cursor_row = result.cursor_row + 1
    cursor_col = result.cursor_col
  end

  local indent = string.rep("  ", indent_level)
  local inner_indent = string.rep("  ", indent_level + 1)

  local lines = {}
  if not has_children and is_one_liner then
    for _ = 1, part.count do
      local line = indent .. string.format("<%s%s></%s>", part.tag, attr_str, part.tag)
      table.insert(lines, line)
    end
    -- Place cursor between >< of the first one-liner
    local before = string.format("<%s%s>", part.tag, attr_str)
    return {
      lines = lines,
      cursor_row = 1,
      cursor_col = #indent + #before,
    }
  else
    for _ = 1, part.count do
      table.insert(lines, indent .. string.format("<%s%s>", part.tag, attr_str))
      for _, l in ipairs(inner_lines) do
        table.insert(lines, inner_indent .. l)
      end
      table.insert(lines, indent .. string.format("</%s>", part.tag))
    end
    return {
      lines = lines,
      cursor_row = 2,
      cursor_col = indent:len()
    }
  end
end

local function expand_tag()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local row = cursor[1] - 1
  local col = cursor[2]
  local line = vim.api.nvim_get_current_line()
  local before = line:sub(1, col)
  local after = line:sub(col + 2)

  local expr = before:match("([%w%.#:=]+)$")
  if not expr then return ">" end

  vim.schedule(function()
    if expr == "html5" then
      vim.api.nvim_buf_set_lines(0, row, row + 1, false, {
        "<!DOCTYPE html>",
        "<html lang=\"en\">",
        "<head>",
        "    <meta charset=\"UTF-8\">",
        "    <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">",
        "    <title>Document</title>",
        "</head>",
        "<body>",
        "",
        "</body>",
        "</html>"
      })
      vim.api.nvim_win_set_cursor(0, { row + 9, 0 })
    else
      local parts = {}
      for part in expr:gmatch("[^:]+") do
        table.insert(parts, part)
      end

      local result = build_html_with_cursor(parts, 1)
      vim.api.nvim_buf_set_lines(0, row, row + 1, false, result.lines)
      vim.api.nvim_win_set_cursor(0, { row + result.cursor_row - 1, result.cursor_col })
    end
  end)

  return ""
end

function M.setup()
  vim.api.nvim_create_autocmd("FileType", {
    pattern = { "htm", "html" },
    callback = function()
      vim.keymap.set("i", "`", function()
        return expand_tag()
      end, { buffer = true, expr = true, desc = "HTML expand with cursor inside outer tag" })
    end,
  })
end

return M
