-- Lua example (init.lua)
vim.api.nvim_create_autocmd("BufEnter", {
    pattern = "*",
    callback = function()
        if vim.bo.filetype == "" then
local function display_startup()
  local lines = {
    "",
}
-- [u] New File   [h] Help   [q] Quit
  for _, line in ipairs(lines) do
    vim.api.nvim_echo({{line, ""}}, true, {})
  end
end

vim.api.nvim_create_autocmd("VimEnter", {
  pattern = "*",
  callback = display_startup
})

-- Key mappings (as before)
vim.keymap.set('n', '<leader>u', function() vim.cmd('e Untitled.txt') end)
vim.keymap.set('n', '<leader>h', function() vim.cmd('help') end)
vim.keymap.set('n', '<leader>q', function() vim.cmd('q!') end)

-- 
vim.opt.shortmess:append("I")
        else
            vim.opt.number = false
            vim.opt.relativenumber = true
        end
    end,
})
