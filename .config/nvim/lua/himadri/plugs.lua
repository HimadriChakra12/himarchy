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
        name = "nord",
        url = "https://github.com/shaunsingh/nord.nvim.git",
        config = function()
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
  {
    name = "gruvbox",
    url = "https://github.com/ellisonleao/gruvbox.nvim",
    config = function()
    end,
  },
}
