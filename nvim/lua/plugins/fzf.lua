vim.pack.add({ 'https://github.com/ibhagwan/fzf-lua' })

local fzf = require('fzf-lua')
fzf.setup({
    fzf_colors = true,
})
fzf.register_ui_select()

local map = vim.keymap.set
map('n', '<leader>ff', fzf.files, { desc = 'Find files' })
map('n', '<leader>fg', fzf.live_grep, { desc = 'Live grep' })
map('n', '<leader>fs', fzf.grep_cword, { desc = 'Grep word under cursor' })
map('n', '<leader>fc', function()
    fzf.grep({ search = vim.fn.expand('%:t:r') })
end, { desc = 'Grep current file name' })
map('n', '<leader>fb', fzf.buffers, { desc = 'Buffers' })
map('n', '<leader>fo', fzf.oldfiles, { desc = 'Recent files' })
map('n', '<leader>fq', fzf.quickfix, { desc = 'Quickfix list' })
map('n', '<leader>fd', fzf.diagnostics_document, { desc = 'Document diagnostics' })
map('n', '<leader>fh', fzf.helptags, { desc = 'Help tags' })
map('n', '<leader>fk', fzf.keymaps, { desc = 'Keymaps' })
map('n', '<leader>fr', fzf.resume, { desc = 'Resume last search' })
map('n', '<leader>fi', function()
    fzf.files({ cwd = vim.fn.stdpath('config') })
end, { desc = 'Find config files' })
