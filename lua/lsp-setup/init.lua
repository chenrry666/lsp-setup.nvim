local M = {}

--- @class LspSetup.Options
M.opts = {
    capabilities = vim.lsp.protocol.make_client_capabilities(),
    --- @diagnostic disable-next-line: unused-local
    on_attach = function(client, bufnr) end,
    --- @type table<string, table|function>
    servers = {},
}

--- @param user_opts LspSetup.Options
function M.setup(user_opts)
    if vim.fn.has('nvim-0.8') ~= 1 then
        vim.notify_once('LSP setup requires Neovim 0.8.0+', vim.log.levels.ERROR)
        return
    end
    -- Do we have mason?
    local ok1, mason = pcall(require, 'mason')
    local ok2, mason_lspconfig = pcall(require, 'mason-lspconfig')

    local servers = {}
    local ensure_install = {}

    if ok1 and ok2 and not mason.has_setup then
        mason.setup {}
        mason_lspconfig.setup {}
    end

    M.opts = vim.tbl_deep_extend('force', M.opts, user_opts)

    for server_name, config in pairs(M.opts.servers) do
        if type(config) == 'function' then
            config = config()
        end

        if type(config) == 'table' then
            config = vim.tbl_deep_extend('keep', config, {
                on_attach = M.opts.on_attach,
                capabilities = M.opts.capabilities,
            })
        end

        -- local is_installed = vim.fn.executable(
        --         require("lspconfig.server_configurations." .. server_name).default_config.cmd[1]) == 1
        -- TODO this is time costly to check if the file executable
        -- for instance my 10 servers costs ~60ms
        --
        -- if not is_installed then
        --     table.insert(ensure_install, server_name)
        -- end

        require('lspconfig')[server_name].setup(config)
    end

    -- mason_lspconfig.setup {
    --     ensure_installed = ensure_install
    -- }
    mason_lspconfig.setup_handlers({
        function(server_name)
            local config = servers[server_name] or nil
            -- only setup the servers that we don't manually setup
            if config == nil then
                config = {
                    on_attach = M.opts.on_attach,
                    capabilities = M.opts.capabilities
                }
                require('lspconfig')[server_name].setup(config)
            end
        end,
    })
end

return M
