local ls = require("luasnip")
local s = ls.snippet
local t = ls.text_node

return {
	s("todo", {
		t("<!-- TODO 🚧: "),
		t({ "", "" }),
		t(" -->"),
	}),
	s("warn", {
		t("<!-- WARNING ⚠️: "),
		t({ "", "" }),
		t(" -->"),
	}),
	s("note", {
		t("<!-- NOTE 📝: "),
		t({ "", "" }),
		t(" -->"),
	}),
	s("hack", {
		t("<!-- HACK 💀: "),
		t({ "", "" }),
		t(" -->"),
	}),
}
