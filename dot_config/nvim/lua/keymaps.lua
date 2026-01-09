-- Keybindings
local keymap = vim.keymap.set

-- Cmd-o (Mac) / Ctrl-o to trigger :Tv files
keymap('n', '<D-o>', ':Tv files<CR>', { desc = 'Open Television file picker' })
keymap('n', '<C-o>', ':Tv files<CR>', { desc = 'Open Television file picker' })

-- Alt-left for jumplist back
keymap('n', '<M-Left>', '<C-o>', { desc = 'Jump back' })

-- Alt-right for jumplist forward
keymap('n', '<M-Right>', '<C-i>', { desc = 'Jump forward' })

-- Show diagnostic/error message under cursor
keymap('n', '<leader>e', vim.diagnostic.open_float, { desc = 'Show error message' })
keymap('n', 'K', vim.lsp.buf.hover, { desc = 'Show hover information' })
