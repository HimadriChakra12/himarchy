-- ~/.config/nvim/lua/popup_explorer/init.lua
local M = {}

function M.open()
  -- ── Netrw Enhanced Setup ────────────────────────────────
  vim.g.netrw_banner = 0              -- Hide banner
  vim.g.netrw_liststyle = 3           -- Tree view
  vim.g.netrw_browse_split = 0        -- Open in current window
  vim.g.netrw_altv = 1                -- Split to the right
  vim.g.netrw_winsize = 25
  vim.g.netrw_keepdir = 0
  vim.g.netrw_localcopydircmd = 'cp -r'

  -- ── Open Explorer ───────────────────────────────────────
  vim.cmd("vertical Lexplore")
  vim.cmd("vertical resize 30")

  -- ── Netrw Keybindings Setup ─────────────────────────────
  vim.api.nvim_create_autocmd("FileType", {
    pattern = "netrw",
    callback = function()
      local opts = { buffer = true, noremap = true, silent = true }

      -- File/Dir management
      vim.keymap.set('n', 'n', ':call NetrwNewFile()<CR>', opts) -- New file
      vim.keymap.set('n', 'N', ':call NetrwNewDir()<CR>', opts)  -- New directory

      -- Refresh & Hidden toggle
      vim.keymap.set('n', 'r', ':Rexplore<CR>', opts) -- Refresh
      vim.keymap.set('n', '.', 'gh', opts)            -- Toggle hidden files

      -- Open in splits or tabs
      vim.keymap.set('n', 'v', '<C-w>v', opts)        -- Open in vertical split
      vim.keymap.set('n', 's', '<C-w>s', opts)        -- Open in horizontal split
      vim.keymap.set('n', 't', ':tabnew %<CR>', opts) -- Open in new tab

      -- Quit manually
      vim.keymap.set('n', 'q', ':bd<CR>', opts)       -- Quit explorer

      -- ── Auto close when file opened ─────────────────────
      vim.api.nvim_create_autocmd("BufEnter", {
        group = vim.api.nvim_create_augroup("AutoCloseNetrw", { clear = true }),
        callback = function()
          local ft = vim.bo.filetype
          if ft ~= "netrw" then
            for _, win in ipairs(vim.api.nvim_list_wins()) do
              local buf = vim.api.nvim_win_get_buf(win)
              if vim.bo[buf].filetype == "netrw" then
                vim.api.nvim_win_close(win, true)
              end
            end
          end
        end,
      })
    end,
  })
end

return M
