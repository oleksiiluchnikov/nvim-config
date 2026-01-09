--[[
    UI Module
    Handles colorscheme, telescope highlights, and UI-related setup
--]]

local M = {}

function M.setup()
    -- Load colorscheme asynchronously
    vim.schedule(function()
        vim.cmd('silent! colorscheme catppuccin')
    end)

    -- Setup telescope highlights after colorscheme
    vim.api.nvim_create_autocmd('ColorScheme', {
        pattern = '*',
        callback = function()
            local ok, pickers = pcall(require, 'plugins.telescope.pickers')
            if ok and pickers.setup_highlights then
                vim.defer_fn(pickers.setup_highlights, 50)
            end
        end,
        desc = 'Setup telescope highlights after colorscheme change',
    })

    -- Load utilities
    require('config.utils.floatterminal').setup()
    require('config.utils.string_preview')
    require('scripts.diagnostics').setup()
    require('plugins.telescope.pickers')

    -- Create EditString command
    vim.api.nvim_create_user_command('EditString', function()
        require('config.string_preview').edit_string()
    end, { desc = 'Edit long string in floating window' })
end

return M
