-- luasnip.lua

local ls = require("luasnip")
local types = require("luasnip.util.types")

-- Load snippets from custom directory
require("luasnip.loaders.from_lua").lazy_load({
	paths = "~/.config/nvim/lua/snippets",
})

-- Optional: load vscode-style snippets (e.g. friendly-snippets)
-- require("luasnip.loaders.from_vscode").lazy_load()

-- Configuration
ls.config.set_config({
	history = true,
	updateevents = "TextChanged,TextChangedI",
	enable_autosnippets = false,
	ext_opts = {
		[types.choiceNode] = {
			active = {
				virt_text = { { "<-", "Error" } },
			},
		},
	},
})

-- Keymaps
vim.keymap.set({ "i", "s" }, "<C-k>", function()
	if ls.expand_or_jumpable() then
		ls.expand_or_jump()
	end
end, { silent = true, desc = "LuaSnip expand or jump" })

vim.keymap.set({ "i", "s" }, "<C-j>", function()
	if ls.jumpable(-1) then
		ls.jump(-1)
	end
end, { silent = true, desc = "LuaSnip jump backwards" })

vim.keymap.set("i", "<C-l>", function()
	if ls.choice_active() then
		ls.change_choice(1)
	end
end, { silent = true, desc = "LuaSnip change choice" })
