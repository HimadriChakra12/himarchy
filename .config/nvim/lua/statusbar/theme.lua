-- Set the statusline background to the same color as the background.
vim.api.nvim_set_hl(0, "StatusLine", { bg = "NONE" })
vim.api.nvim_set_hl(0, "StatusLineNC", { bg = "NONE" })

local function set_statusline_background()
  local bg_color = vim.api.nvim_get_hl(0, { name = "Normal" }).bg
  if bg_color then
    vim.api.nvim_set_hl(0, "StatusLine", { bg = bg_color })
    vim.api.nvim_set_hl(0, "StatusLineNC", { bg = bg_color })
  else
    -- Fallback to "NONE" if Normal's background is not set.
    vim.api.nvim_set_hl(0, "StatusLine", { bg = "NONE" })
    vim.api.nvim_set_hl(0, "StatusLineNC", { bg = "NONE" })
  end
end

-- Run the function once at startup.
set_statusline_background()

-- Run the function again when the colorscheme changes.
vim.api.nvim_create_autocmd("ColorScheme", {
  callback = set_statusline_background,
})

-- Function to set the statusline appearance
  local gruvbox_fg_yellow = "#d79921"
  local gruvbox_fg_aqua = "#689d6a"
  local gruvbox_fg_red = "#cc241d"
  local gruvbox_fg_blue = "#458588"
  local gruvbox_fg_purple = "#b16286"
  local gruvbox_fg_green = "#98971a"

  -- Set highlight groups for the statusline
  vim.api.nvim_set_hl(0, "StatusLine", {
    fg = gruvbox_fg_yellow,
    bold = true,
  })

  vim.api.nvim_set_hl(0, "StatusLineNC", {
    fg = gruvbox_fg_aqua,
  })
