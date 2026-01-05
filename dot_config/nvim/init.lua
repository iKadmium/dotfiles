vim.opt.number = true
vim.opt.relativenumber = true

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
require("lazy").setup({
    require("colors"), -- This passes the table from lua/colors.lua to lazy
})

-- Load and run the Nushell logic
require("nushell").setup()
