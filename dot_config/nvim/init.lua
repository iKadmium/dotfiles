vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.softtabstop = -1  -- A value of -1 makes softtabstop use shiftwidth
vim.opt.expandtab = false -- or vim.opt.noexpandtab = true
vim.opt.smartindent = true
vim.opt.autoindent = true

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
    vim.fn.system({
        "git",
        "clone",
        "--filter=blob:none",
        "https://github.com/folke/lazy.nvim.git",
        "--branch=stable",
        lazypath,
    })
end
-- Use the direct vim.opt syntax
vim.opt.rtp:prepend(lazypath)

-- Setup plugins
require("lazy").setup("plugins")

-- Load keybindings
require("keymaps")

-- Load and run the Nushell logic
require("nushell").setup()
