return {
    {
        name = "telescope",
        url = "https://github.com/nvim-telescope/telescope.nvim",
        dependencies = {
            { url = "https://github.com/nvim-lua/plenary.nvim" },
        },
        config = function()
            require("telescope")
        end
    },
    {
        name = "Undotree",
        url = "https://github.com/mbbill/undotree",
        config = function()
            require("Undotree").setup()
        end,
    },
    {
        name = "vim-dadbod",
        url = "https://github.com/tpope/vim-dadbod",
        config = function()
            require("vim-dadbod")
        end,
    },
    {
        name = "vim-dadbod-ui",
        url = "https://github.com/kristijanhusak/vim-dadbod-ui",
        config = function()
            require("vim-dadbod")
        end,
    },
    {
        name = "fugitive",
        url = "https://github.com/tpope/vim-fugitive",
        config = function()
            require("fugitive")
        end,
    },
    {
        name = "buffer_manager",
        url = "https://github.com/j-morano/buffer_manager.nvim",
        config = function()
            require("buffer_manager")
        end,
    },
    {
        name = "nvim-autopairs",
        url = "https://github.com/windwp/nvim-autopairs",
        config = function()
            require('nvim-autopairs').setup({
                disable_in_macro = true, -- disable when recording or executing a macro
                disable_in_visualblock = false, -- disable when insert after visual block mode
                disable_in_replace_mode = true,
                ignored_next_char = [=[[%w%%%'%[%"%.%`%$]]=],
                enable_moveright = true,
                enable_afterquote = true, -- add bracket pairs after quote
                enable_check_bracket_line = true, --- check bracket in same line
                enable_bracket_in_quote = true, --
                enable_abbr = false, -- trigger abbreviation
                break_undo = true, -- switch for basic rule break undo sequence
                check_ts = false,
                map_cr = true,
                map_bs = true, -- map the <BS> key
                map_c_h = false, -- Map the <C-h> key to delete a pair
                map_c_w = false, -- map <c-w> to delete a pair if possible
            })
        end,
    },
    {
        name = "nord",
        url = "https://github.com/shaunsingh/nord.nvim.git",
        config = function()
        end,
    }, 
    {
        name = "symbols-outline",
        url = "https://github.com/simrat39/symbols-outline.nvim",
        config = function()
            require("symbols-outline").setup({
                highlight_hovered_item = true,
                show_guides = true,
                auto_preview = false,
                position = 'right',
                relative_width = true,
                width = 25,
                auto_close = false,
                show_numbers = false,
                show_relative_numbers = false,
                show_symbol_details = true,
                preview_bg_highlight = 'Pmenu',
                autofold_depth = nil,
                auto_unfold_hover = true,
                fold_markers = { '', '' },
                wrap = false,
                keymaps = { -- These keymaps can be a string or a table for multiple keys
                    close = {"<Esc>", "q"},
                    goto_location = "<Cr>",
                    focus_location = "o",
                    hover_symbol = "<C-space>",
                    toggle_preview = "K",
                    rename_symbol = "r",
                    code_actions = "a",
                    fold = "h",
                    unfold = "l",
                    fold_all = "W",
                    unfold_all = "E",
                    fold_reset = "R",
                },
                lsp_blacklist = {},
                symbol_blacklist = {},
                symbols = {
                    File = { icon = "", hl = "@text.uri" },
                    Module = { icon = "", hl = "@namespace" },
                    Namespace = { icon = "", hl = "@namespace" },
                    Package = { icon = "", hl = "@namespace" },
                    Class = { icon = "𝓒", hl = "@type" },
                    Method = { icon = "ƒ", hl = "@method" },
                    Property = { icon = "", hl = "@method" },
                    Field = { icon = "", hl = "@field" },
                    Constructor = { icon = "", hl = "@constructor" },
                    Enum = { icon = "ℰ", hl = "@type" },
                    Interface = { icon = "ﰮ", hl = "@type" },
                    Function = { icon = "", hl = "@function" },
                    Variable = { icon = "", hl = "@constant" },
                    Constant = { icon = "", hl = "@constant" },
                    String = { icon = "𝓐", hl = "@string" },
                    Number = { icon = "#", hl = "@number" },
                    Boolean = { icon = "⊨", hl = "@boolean" },
                    Array = { icon = "", hl = "@constant" },
                    Object = { icon = "⦿", hl = "@type" },
                    Key = { icon = "🔐", hl = "@type" },
                    Null = { icon = "NULL", hl = "@type" },
                    EnumMember = { icon = "", hl = "@field" },
                    Struct = { icon = "𝓢", hl = "@type" },
                    Event = { icon = "🗲", hl = "@type" },
                    Operator = { icon = "+", hl = "@operator" },
                    TypeParameter = { icon = "𝙏", hl = "@parameter" },
                    Component = { icon = "", hl = "@function" },
                    Fragment = { icon = "", hl = "@constant" },
                },
            })
        end,
    },
  {
    name = "vim-markdown",
    url = "https://github.com/preservim/vim-markdown",
    config = function()
      require("vim-markdown").setup()
    end,
  },
  {
    name = "sqlite.lua",
    url = "https://github.com/kkharji/sqlite.lua",
    config = function()
      require("sqlite")
    end,
  },
}
