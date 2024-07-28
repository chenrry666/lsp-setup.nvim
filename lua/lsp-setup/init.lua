local M = {}

--- @class LspSetup.Options
--- @field capabilities lsp.ClientCapabilities|nil client capabilities
--- @field on_attach vim.lsp.client.on_attach_cb|nil deprecated, in favor of LspAttach autocmd
--- @field servers table<string, table|function> config list

--- @param user_opts LspSetup.Options
function M.setup(user_opts)
    if vim.fn.has('nvim-0.9') ~= 1 then
        vim.notify_once('LSP setup requires Neovim 0.9+', vim.log.levels.ERROR)
        return
    end

    if user_opts.on_attach then
        vim.deprecate("on_attach", "LspAttach autocmd", "next", "lsp-setup", true)
    end

    local lspconfig = require 'lspconfig'
    if not user_opts.capabilities then
        lspconfig.util.default_config.capabilities = vim.lsp.protocol.make_client_capabilities()
    else
        lspconfig.util.default_config.capabilities = user_opts.capabilities
    end

    local servers = {}
    local ensure_install = {}

    for server_name, config in pairs(user_opts.servers) do
        if type(config) == 'function' then
            config = config()
        end

        if config.on_attach then
            vim.deprecate(server_name .. "on_attach", "LspAttach autocmd", "next", "lsp-setup", true)
        end

        -- local is_installed = vim.fn.executable(
        --         require("lspconfig.server_configurations." .. server_name).default_config.cmd[1]) == 1
        -- TODO this is time costly to check if the file executable
        -- for instance my 10 servers costs ~60ms
        --
        -- if not is_installed then
        --     table.insert(ensure_install, server_name)
        -- end

        lspconfig[server_name].setup(config)
    end

    local ok1, mason = pcall(require, 'mason')
    local ok2, mason_lspconfig = pcall(require, 'mason-lspconfig')

    if ok1 and ok2 and not mason.has_setup then
        mason.setup {}
        mason_lspconfig.setup {}
    end

    mason_lspconfig.setup_handlers({
        function(server_name)
            local config = servers[server_name] or nil
            -- only setup the servers that we don't manually setup
            if config == nil then
                lspconfig[server_name].setup {}
            end
        end,
    })
end

return M
