local M = {}

--- Get the project root directory of the current file or the given path.
--- @param path? string Optional path to search, defaults to current buffer or cwd
--- @param opts? table Options: { respect_cwd = true } to force using cwd
--- @return string
function M.get_root_dir(path, opts)
    opts = opts or {
        respect_cwd = true,
    }

    -- 1. Resolve base path
    if not path or path == '' then
        path = vim.fn.expand('%:p:h') -- Use current file's directory, not cwd
        if path == '' then
            path = vim.fn.getcwd()
        end
    end

    -- 2. If opts.respect_cwd is true, check if cwd has changed from LSP root
    local cwd = vim.fn.getcwd()

    -- 3. Try Git root first (more reliable for directory changes)
    local git = require('config.utils.git')
    local git_root = git.get_root_dir(path)
    if git_root and git_root ~= '' then
        -- Check if cwd is within git_root or if we've explicitly changed directory
        if opts.respect_cwd and not vim.startswith(cwd, git_root) then
            return cwd
        end
        return git_root
    end

    -- 4. LSP workspace root (only if still relevant to cwd)
    local clients = vim.lsp.get_clients({ bufnr = 0 })
    for _, client in ipairs(clients) do
        local lsp_root

        -- new-style workspace_folders
        local ws_folders = client.config.workspace_folders
        if ws_folders and #ws_folders > 0 then
            local uri = ws_folders[1].uri or ws_folders[1].name
            if uri then
                lsp_root = vim.uri_to_fname(uri)
            end
        end

        -- fallback to root_dir in config
        if not lsp_root and client.config.root_dir then
            lsp_root = client.config.root_dir
        end

        -- Only use LSP root if cwd is within it
        if lsp_root and lsp_root ~= '' then
            if vim.startswith(cwd, lsp_root) then
                return lsp_root
            end
        end
    end

    -- 5. Fallback to current working dir
    return cwd
end

--- Get the project root, always respecting cwd changes
--- @param path? string Optional path to search
--- @return string
function M.get_root_dir_respect_cwd(path)
    return M.get_root_dir(path, { respect_cwd = true })
end

return M
