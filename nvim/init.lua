vim.loader.enable()

vim.g.mapleader = ' '
vim.g.c_syntax_for_h = true

local opt = vim.opt

opt.number = true
opt.relativenumber = true

opt.tabstop = 4
opt.shiftwidth = 4
opt.expandtab = true

opt.ignorecase = true
opt.smartcase = true
opt.inccommand = 'split'

opt.signcolumn = 'yes'
opt.cursorline = true
opt.colorcolumn = '80'
opt.showmode = false
opt.winborder = 'rounded'

opt.clipboard = 'unnamedplus'

opt.splitbelow = true
opt.splitright = true

opt.scrolloff = 8

opt.swapfile = false
opt.undofile = true

local map = vim.keymap.set

map('x', 'J', ":m '>+1<CR>gv=gv", { silent = true, desc = 'Move selection down' })
map('x', 'K', ":m '<-2<CR>gv=gv", { silent = true, desc = 'Move selection up' })

map('n', 'J', 'mzJ`z')
map('n', '<C-d>', '<C-d>zz')
map('n', '<C-u>', '<C-u>zz')
map('n', 'n', 'nzzzv')
map('n', 'N', 'Nzzzv')

map({ 'n', 'x' }, '<leader>d', [["_d]], { desc = 'Delete without yanking' })

map('i', '<C-c>', '<Esc>')

map('n', '<leader>co', '<cmd>copen<CR>', { desc = 'Open quickfix' })
map('n', '<leader>cl', '<cmd>cclose<CR>', { desc = 'Close quickfix' })

map('n', '<leader>s', [[:s/\<<C-r><C-w>\>//gI<Left><Left><Left>]], { desc = 'Replace word under cursor' })
map('n', '<leader>x', '<cmd>!chmod +x %:S<CR>', { silent = true, desc = 'Make file executable' })

vim.cmd.packadd('nvim.undotree')
map('n', '<leader>u', '<cmd>Undotree<CR>', { desc = 'Toggle undotree' })

map('n', '<leader>rl', '<cmd>restart<CR>', { desc = 'Restart Neovim' })

vim.api.nvim_create_autocmd('TextYankPost', {
    group = vim.api.nvim_create_augroup('config', { clear = true }),
    callback = function()
        vim.hl.on_yank()
    end,
})

require('plugins.colorscheme')
require('plugins.mini')
require('plugins.treesitter')
require('plugins.lsp')
require('plugins.completion')
require('plugins.fzf')
require('plugins.oil')
require('plugins.terminal')
