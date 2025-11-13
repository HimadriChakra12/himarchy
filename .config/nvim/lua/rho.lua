-- /lua/..
require('keybindings')
-- require('netwr')
require("pacman.bricks")
require("plugs")
require("dashboard")
require("usrcmd")
require("heads")
--require("sql")
require("netwr")
require("reader")
require("todo")
require("todo_popup")

-- /csode/..
-- require("csode.options")

-- /lua/statusline..
require("statusbar.style")
require("statusbar.theme")

-- /lua/snippets..
-- require("snippets.markdown")
require("snippets.html").setup()
require("snippets.swiss").setup()
-- require("snippets.goyomd")

-- lua/plugins..
require("plugins.nvim_compile")
require("plugins.lsp")
require("plugins.markdown_link_nav")
require('plugins.pcmp').setup()
require("plugins.buffershift")
--require("plugins.explorer")
require("plugins.zoxide").setup() 
require("plugins.termin").setup()
--require("plugins.shell")
require("plugins.pin")
require("plugins.browser")


