--[[
    Keymaps Module
    All keybindings organized in one place
--]]

local M = {}

function M.setup()
    local ai = require('config.ai')

    -- Window Focus (Fast switching)
    vim.keymap.set('n', '<Left>', '<C-w>h', { desc = 'Focus Left' })
    vim.keymap.set('n', '<Right>', '<C-w>l', { desc = 'Focus Right' })

    -- AI Accept Keymaps
    vim.keymap.set({ 'n', 'i', 'c', 't' }, '<C-y>', function()
        ai.accept_suggestion('word')
    end, { desc = 'AI: Accept Word' })

    vim.keymap.set({ 'n', 'i', 'c', 't' }, '<C-j>', function()
        ai.accept_suggestion('full')
    end, { desc = 'AI: Accept Full Suggestion' })

    vim.keymap.set({ 'n', 'i', 'c', 't' }, '<C-l>', function()
        ai.accept_suggestion('line')
    end, { desc = 'AI: Accept Line (Cursor to EOL)' })

    -- Smart Navigation (Up/Down)
    vim.keymap.set({ 'n', 'i', 'v' }, '<Up>', function()
        ai.smart_nav('up')
    end, { desc = 'Smart Up' })

    vim.keymap.set({ 'n', 'i', 'v' }, '<Down>', function()
        ai.smart_nav('down')
    end, { desc = 'Smart Down' })

    vim.keymap.set({ 'n', 'i', 'v' }, '<C-Down>', function()
        ai.smart_nav('down')
    end, { desc = 'Smart Down (C-Down)' })

    -- CodeCompanion
    vim.keymap.set({ 'n', 'v' }, '<leader>j', function()
        vim.cmd([[CodeCompanionChat]])
    end, { desc = 'CodeCompanion: Toggle chat buffer' })

    vim.keymap.set({ 'n', 'v' }, '<leader>x', function()
        vim.cmd([[CodeCompanionChat Add]])
    end, { desc = 'CodeCompanion: Add selection to chat' })

    -- String Preview
    vim.keymap.set('n', '<leader>es', function()
        require('config.utils.string_preview').edit_string()
    end, { desc = 'Utils: Edit long string in floating window' })

    -- Change Directory
    vim.keymap.set('n', '<leader>cd', function()
        local root = vim.fn.expand('%:p:h') -- Get the directory of the current file
        -- Remove oil: prefix from oil.nvim if it exists
        root = root:gsub('^oil://', '')

        if root and root ~= '' then
            vim.cmd('cd ' .. vim.fn.fnameescape(root)) -- Change directory to the root
            -- Display a notification with the new directory
            vim.notify('Changed directory to: ' .. root, vim.log.levels.INFO, {
                timeout = 1500, -- Set a longer timeout for better readability
            })
        else
            -- Show a warning if the directory can't be determined
            vim.notify(
                'Could not determine a valid root directory.',
                vim.log.levels.WARN,
                {
                    timeout = 1500,
                }
            )
        end
    end, { desc = 'Project: Change to file directory' })

    -- Make Test
    vim.keymap.set('n', '<leader>m', function()
        vim.cmd('!make test')
    end, { desc = 'Project: Run make test' })
end

return M
