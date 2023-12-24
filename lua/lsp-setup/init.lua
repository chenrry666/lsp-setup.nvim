local utils = require('lsp-setup.utils')
local inlay_hints = require('lsp-setup.inlay_hints')

local function lsp_servers(opts)
    local servers = {}
    for server, config in pairs(opts.servers) do
        local server_name, _ = utils.parse_server(server)

        if type(config) == 'function' then
            config = config()
        end

        if type(config) == 'table' then
            config = vim.tbl_deep_extend('keep', config, {
                on_attach = opts.on_attach,
                capabilities = opts.capabilities,
                settings = {},
            })
        end

        servers[server_name] = config
    end

    return servers
end

local M = {}

--- @class LspSetup.Options
M.opts = {
    --- @type table<string, string|function>
    mappings = {},
    capabilities = vim.lsp.protocol.make_client_capabilities(),
    --- @diagnostic disable-next-line: unused-local
    on_attach = function(client, bufnr) end,
    --- @type table<string, table|function>
    servers = {},
    inlay_hints = inlay_hints.opts,
}

--- @param user_opts LspSetup.Options
function M.setup(user_opts)
    if vim.fn.has('nvim-0.8') ~= 1 then
        vim.notify_once('LSP setup requires Neovim 0.8.0+', vim.log.levels.ERROR)
        return
    end

    M.opts = vim.tbl_deep_extend('force', M.opts, user_opts)

    vim.api.nvim_create_augroup('LspSetup', {})
    vim.api.nvim_create_autocmd('LspAttach', {
        group = 'LspSetup',
        callback = function(args)
            local bufnr = args.buf
            local mappings = M.opts.mappings
            utils.mappings(bufnr, mappings)
        end,
    })

    inlay_hints.setup(M.opts.inlay_hints)
    local servers = lsp_servers(M.opts)

    local ok1, mason = pcall(require, 'mason')
    local ok2, mason_lspconfig = pcall(require, 'mason-lspconfig')
    if ok1 and ok2 then
        if mason.has_setup then
            mason.setup()
        end

        mason_lspconfig.setup {}

        mason_lspconfig.setup_handlers({
            function(server_name)
                local config = servers[server_name] or nil
                if config == nil then
                    return
                end
                require('lspconfig')[server_name].setup(config)
            end,
        })

        for server_name, config in pairs(servers) do
            require('lspconfig')[server_name].setup(config)
        end

        return
    else
        for server_name, config in pairs(servers) do
            require('lspconfig')[server_name].setup(config)
        end
    end
end

return M
