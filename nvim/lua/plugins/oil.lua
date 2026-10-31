vim.pack.add({ 'https://github.com/stevearc/oil.nvim' })

require('oil').setup({
    view_options = { show_hidden = true },
})

vim.keymap.set('n', '-', '<cmd>Oil<CR>', { desc = 'Open parent directory' })
