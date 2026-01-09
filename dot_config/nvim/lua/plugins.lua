-- All lazy.nvim plugins
return {
    {
        "Mofiqul/dracula.nvim",
        lazy = false,
        priority = 1000,
        config = function()
            vim.cmd([[colorscheme dracula]])
        end,
    },
    {
        'akinsho/bufferline.nvim',
        version = "*",
        dependencies = 'nvim-tree/nvim-web-devicons',
        config = function()
            require("bufferline").setup {}
        end,
    },
    {
        "alexpasmantier/tv.nvim",
        config = function()
            require("tv").setup {
                -- your config here (see Configuration section below)
            }
        end,
    },
    {
        "LhKipp/nvim-nu",
    },
    {
        "neovim/nvim-lspconfig",
        config = function()
            -- LSP settings are handled by nushell.lua
        end,
    }
}
