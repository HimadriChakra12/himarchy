require("buffer-manager").setup({
  icons = true,
  use_devicons = true,
  default_mappings = true,
  window = {
    width = 0.8,
    height = 0.7,
    border = "rounded",
    preview_width = 0.5,
  },
  style = {
    numbers = "ordinal", -- or "none"
    modified_icon = "●",
    current_icon = "",
    path_style = "shorten", -- "filename", "relative", "absolute", "shorten"
  },
  mappings = {
    open = "<leader>bb",
    vertical = "<leader>bv",
    horizontal = "<leader>bs",
    delete = "<leader>bd",
    delete_force = "<leader>bD",
  },
  sessions = {
    enabled = true,
    auto_save = true,
    session_dir = vim.fn.stdpath("data") .. "/buffer-manager-sessions",
    session_file = "session.json",
    indicator_icon = "󱡅",

    vim.keymap.set("n", "<leader>sl", function()
        require("buffer-manager.session").load_session()
    end, { desc = "BufferManager: Restore session" })
  }
})
