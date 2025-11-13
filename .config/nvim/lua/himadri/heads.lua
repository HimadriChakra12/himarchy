local M = {}

function M.setup()
    -- Define highlight groups
    vim.cmd [[
        highlight MarkdownHeading1 guifg=#FF5555 gui=bold
        highlight MarkdownHeading2 guifg=#FF875F gui=bold
        highlight MarkdownHeading3 guifg=#FFD700 gui=bold
        highlight MarkdownQuote guifg=#AAAAAA gui=italic
        highlight MarkdownBold guifg=#00FF00 gui=bold
        highlight MarkdownItalic guifg=#00FFFF gui=italic
        highlight MarkdownCode guifg=#FF00FF guibg=#1E1E1E
    ]]

    -- Markdown syntax rules
    vim.cmd [[
        syntax match MarkdownHeading1 "^# .*$"
        syntax match MarkdownHeading2 "^## .*$"
        syntax match MarkdownHeading3 "^### .*$"
        syntax match MarkdownQuote "^>.*$"
        syntax match MarkdownBold "\*\*.\{-}\*\*"
        syntax match MarkdownItalic "\*.\{-}\*"
        syntax match MarkdownCode "\v`[^`]+`"
    ]]
end

return M

