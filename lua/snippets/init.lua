---@module 'snippets'
---@description LuaSnip snippet loader and configuration
---@author Your Name
---@license MIT

local M = {}

-- Get the directory where snippets are stored
M.snippets_path = vim.fn.stdpath('config') .. '/lua/snippets'

---Load all snippet files for a given filetype
---@param ft string Filetype to load snippets for
local function load_ft_snippets(ft)
    local ft_path = M.snippets_path .. '/ft/' .. ft .. '.lua'
    if vim.fn.filereadable(ft_path) == 1 then
        local ok, snips = pcall(dofile, ft_path)
        if ok and snips then
            require('luasnip').add_snippets(ft, snips, { key = ft })
        else
            vim.notify(
                string.format(
                    'Error loading snippets for %s: %s',
                    ft,
                    snips or 'unknown'
                ),
                vim.log.levels.WARN,
                { title = 'LuaSnip' }
            )
        end
    end
end

---Load snippets for the current buffer's filetype
function M.load_snippets()
    local ft = vim.bo.filetype
    if ft and ft ~= '' then
        load_ft_snippets(ft)
    end
end

---Reload all snippets
function M.reload_snippets()
    -- Clear all snippets
    require('luasnip').cleanup()

    -- Reload snippet files
    package.loaded['snippets.utils'] = nil
    package.loaded['snippets.ft.all'] = nil

    -- Load global snippets
    local all_path = M.snippets_path .. '/ft/all.lua'
    if vim.fn.filereadable(all_path) == 1 then
        local ok, snips = pcall(dofile, all_path)
        if ok and snips then
            require('luasnip').add_snippets('all', snips, { key = 'all' })
        end
    end

    -- Reload current buffer's snippets
    M.load_snippets()

    vim.notify(
        'LuaSnip snippets reloaded!',
        vim.log.levels.INFO,
        { title = 'LuaSnip' }
    )
end

---Setup autocommand to lazy-load snippets per filetype
function M.setup_lazy_load()
    local group = vim.api.nvim_create_augroup('LuaSnipLoader', { clear = true })

    vim.api.nvim_create_autocmd('FileType', {
        group = group,
        pattern = '*',
        callback = function()
            M.load_snippets()
        end,
    })
end

---Initialize snippet system
function M.init()
    -- Load global snippets immediately
    local all_path = M.snippets_path .. '/ft/all.lua'
    if vim.fn.filereadable(all_path) == 1 then
        local ok, snips = pcall(dofile, all_path)
        if ok and snips then
            require('luasnip').add_snippets('all', snips, { key = 'all' })
        end
    end

    -- Setup lazy loading for filetype-specific snippets
    M.setup_lazy_load()
end

return M
