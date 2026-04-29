local lsp = vim.lsp

if lsp and lsp.get_clients and lsp.buf_get_clients then
    lsp.buf_get_clients = function(bufnr)
        return lsp.get_clients({ bufnr = bufnr or 0 })
    end
end

if lsp and lsp.get_client_by_id and lsp.get_buffers_by_client_id then
    lsp.get_buffers_by_client_id = function(client_id)
        local client = lsp.get_client_by_id(client_id)
        if not client or not client.attached_buffers then
            return {}
        end

        local bufnrs = {}
        for bufnr in pairs(client.attached_buffers) do
            table.insert(bufnrs, bufnr)
        end
        table.sort(bufnrs)

        return bufnrs
    end
end
