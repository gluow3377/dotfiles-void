vim.pack.add({ 'https://github.com/nvim-treesitter/nvim-treesitter-textobjects' })

vim.api.nvim_create_autocmd('FileType', {
    group = vim.api.nvim_create_augroup('config.treesitter', { clear = true }),
    pattern = 'c',
    callback = function(ev)
        vim.treesitter.start(ev.buf)
        vim.wo[0][0].foldmethod = 'expr'
        vim.wo[0][0].foldexpr = 'v:lua.vim.treesitter.foldexpr()'
    end,
})

vim.o.foldlevel = 99
vim.o.foldtext = ''

require('nvim-treesitter-textobjects').setup({
    select = { lookahead = true },
})

local function textobject(lhs, query, desc)
    vim.keymap.set({ 'x', 'o' }, lhs, function()
        require('nvim-treesitter-textobjects.select').select_textobject(query, 'textobjects')
    end, { desc = desc })
end
textobject('af', '@function.outer', 'Around function')
textobject('if', '@function.inner', 'Inside function')
textobject('ac', '@class.outer', 'Around struct')
textobject('ic', '@class.inner', 'Inside struct')
textobject('aa', '@parameter.outer', 'Around argument')
textobject('ia', '@parameter.inner', 'Inside argument')
