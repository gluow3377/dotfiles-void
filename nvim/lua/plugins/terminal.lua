vim.pack.add({ 'https://github.com/akinsho/toggleterm.nvim' })

require('toggleterm').setup({
    open_mapping = [[<C-\>]],
    terminal_mappings = false,
    float_opts = { border = 'rounded' },
})

local map = vim.keymap.set
map('t', [[<C-\><C-\>]], '<cmd>ToggleTerm<CR>', { desc = 'Toggle terminal' })

local lazygit = require('toggleterm.terminal').Terminal:new({
    cmd = 'lazygit',
    direction = 'float',
    hidden = true,
})

map('n', '<leader>gg', function()
    lazygit.dir = vim.fs.root(0, '.git')
    lazygit:toggle()
end, { desc = 'Toggle lazygit' })
