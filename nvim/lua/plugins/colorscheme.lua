vim.pack.add({ 'https://github.com/ellisonleao/gruvbox.nvim' })

require('gruvbox').setup({
    transparent_mode = true,
})
vim.cmd.colorscheme('gruvbox')
