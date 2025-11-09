local lsp = require("lsp-zero").preset({
    name = "recommended",
    set_lsp_keymaps = false, -- <- this disables automatic keymaps
    manage_nvim_cmp = true,
    suggest_lsp_servers = true,
})

lsp.on_attach(function(client, bufnr)
    local opts = { buffer = bufnr, remap = false }
    vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
    vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
    vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
    vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts)
    vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
end)

-- Make sure servers are installed
require("mason").setup()
require("mason-lspconfig").setup({
    ensure_installed = {
        "lua_ls", -- Lua
        "pyright", -- Python
        "ts_ls", -- TypeScript
        "bashls", -- Bash
    },
    automatic_installation = true,
})
lsp.setup()
local cmp = require("cmp")
cmp.setup({
    mapping = cmp.mapping.preset.insert({
        ["<Tab>"] = cmp.mapping.select_next_item(),
        ["<S-Tab>"] = cmp.mapping.select_prev_item(),
        ["<C-Space>"] = cmp.mapping.confirm({ select = true }),
    }),
    sources = {
        { name = "nvim_lsp" },
        { name = "buffer" },
        { name = "path" },
    },
})
