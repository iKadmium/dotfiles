local M = {}

function M.setup()
    local function start_nu_lsp()
        local root = vim.fs.root(0, { '.git', 'env.nu', 'config.nu' }) or vim.fn.getcwd()
        vim.lsp.start({
            name = 'nushell',
            cmd = { 'nu', '--lsp' },
            root_dir = root,
        })
    end

    vim.api.nvim_create_autocmd("FileType", {
        pattern = "nu",
        callback = start_nu_lsp,
    })
end

return M
