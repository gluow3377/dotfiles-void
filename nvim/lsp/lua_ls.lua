local markers = {
    '.luarc.json',
    '.luarc.jsonc',
    '.stylua.toml',
    'stylua.toml',
    '.git',
}

local function has_luarc(root)
    return vim.uv.fs_stat(root .. '/.luarc.json')
        or vim.uv.fs_stat(root .. '/.luarc.jsonc')
end

local function library()
    local config = vim.fn.stdpath('config')
    local paths = {}
    for _, path in ipairs(vim.api.nvim_list_runtime_paths()) do
        local lua = path .. '/lua'
        if not vim.fs.relpath(config, path) and vim.uv.fs_stat(lua) then
            table.insert(paths, lua)
        end
    end
    return paths
end

return {
    cmd = { 'lua-language-server' },
    filetypes = { 'lua' },
    root_dir = function(bufnr, on_dir)
        local name = vim.api.nvim_buf_get_name(bufnr)
        for _, path in ipairs(vim.api.nvim_list_runtime_paths()) do
            if vim.fs.relpath(path, name) then
                on_dir(vim.fn.stdpath('config'))
                return
            end
        end
        on_dir(vim.fs.root(bufnr, markers))
    end,
    before_init = function(_, config)
        if config.root_dir and has_luarc(config.root_dir) then
            return
        end
        local settings = config.settings.Lua
        settings.runtime = {
            version = 'LuaJIT',
            path = { 'lua/?.lua', 'lua/?/init.lua' },
        }
        settings.workspace.library = library()
    end,
    settings = {
        Lua = {
            workspace = { checkThirdParty = false },
            hint = { enable = true },
        },
    },
}
