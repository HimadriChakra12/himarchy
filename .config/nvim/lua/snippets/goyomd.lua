vim.api.nvim_create_autocmd("FileType", {
  pattern = "markdown",
  command = "Goyo",
})

vim.api.nvim_create_autocmd("User", {
  pattern = "GoyoLeave",
  callback = function()
    -- Only quit if the filetype is markdown and we're in Goyo mode
    if vim.bo.filetype == "markdown" then
      vim.cmd("q")
    end
  end,
})

vim.keymap.set("n", ":bd", function()
  if vim.fn.exists("#User#GoyoEnter") == 1 then
    vim.cmd("Goyo!")
  end
  vim.cmd("bd")
  vim.cmd("q")
end, { expr = false })
