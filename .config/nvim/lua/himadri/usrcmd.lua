vim.api.nvim_create_user_command("PacmanSync", function()
  require("pacman.ghost").setup()
end, {})
vim.api.nvim_create_user_command("PacmanDash", function()
  require("pacman.maze").open()
end, {})
vim.api.nvim_create_user_command("PacmanDashboard", function()
  require("pacman.maze").open()
end, {})
vim.api.nvim_create_user_command(
  "ReaderMode",
  function()
    ToggleReaderMode()
  end,
  { desc = "Toggle distraction-free reader mode" }
)
vim.keymap.set("n", "<leader>t", "<cmd>lua require('himadri.todo').telescope_todo_popup()<CR>", { noremap=true, silent=true })

