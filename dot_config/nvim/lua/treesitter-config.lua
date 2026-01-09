-- Treesitter configuration
local M = {}

function M.setup()
    require("nvim-treesitter.configs").setup {
        ensure_installed = { "lua", "vim", "vimdoc", "nu" },
        auto_install = true,
        highlight = {
            enable = true,
        },
        indent = {
            enable = true,
        },
    }
end

return M
