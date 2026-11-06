local function switch_source_header(client, bufnr)
    local params = vim.lsp.util.make_text_document_params(bufnr)
    client:request('textDocument/switchSourceHeader', params, function(err, result)
        if err then
            vim.notify(tostring(err), vim.log.levels.ERROR)
        elseif not result then
            vim.notify('No matching source/header file found')
        else
            vim.cmd.edit(vim.uri_to_fname(result))
        end
    end, bufnr)
end

return {
    cmd = { 'clangd', '--fallback-style=WebKit' },
    filetypes = { 'c' },
    root_markers = {
        '.clangd',
        '.clang-tidy',
        '.clang-format',
        'compile_commands.json',
        'compile_flags.txt',
        'configure.ac',
        '.git',
    },
    capabilities = {
        textDocument = { completion = { editsNearCursor = true } },
    },
    on_attach = function(client, bufnr)
        vim.keymap.set('n', '<leader>ch', function()
            switch_source_header(client, bufnr)
        end, { buffer = bufnr, desc = 'Switch source/header' })
    end,
}
