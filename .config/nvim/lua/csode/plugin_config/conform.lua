local conform = require("conform")

conform.setup({
    -- Define formatters per filetype
    formatters_by_ft = {
        lua = { "stylua" },
        python = { "black" },
        javascript = { "prettier" },
        typescript = { "prettier" },
        json = { "prettier" },
        html = { "prettier" },
        css = { "prettier" },
        sh = { "shfmt" },
        cpp = { "clang_format" },
        c = { "clang_format" },
    },
})
