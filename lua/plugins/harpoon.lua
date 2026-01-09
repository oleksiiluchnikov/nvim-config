return {
    {
        -- [harpoon.nvim](https://github.com/ThePrimeagen/harpoon)
        -- Navigating to files/buffers blazingly fast
        -----------------------------------------------------------------------
        'ThePrimeagen/harpoon',
        branch = 'harpoon2',
        --- @type HarpoonPartialConfig
        opts = {
            menu = {
                width = vim.api.nvim_win_get_width(0) - 10,
            },
            settings = {
                save_on_toggle = true,
                save_on_change = true,
                enter_on_sendcmd = false,
                tmux_autoclose_windows = false,
                excluded_filetypes = {
                    'harpoon',
                },
                mark_branch = false,
                tabline = false,
                tabline_prefix = '   ',
                tabline_suffix = '   ',
            },
        },
        keys = {
            {
                '<leader>a',
                function()
                    require('harpoon'):list():add()
                    vim.notify(
                        'Added: ' .. tostring(vim.fn.expand('%')),
                        vim.log.levels.INFO,
                        {
                            title = 'Harpoon',
                            timeout = 100,
                        }
                    )
                end,
                { silent = true, desc = 'add file to harpoon' },
            },
            {
                '<leader>j',
                function()
                    require('harpoon.ui').toggle_quick_menu(
                        require('harpoon'):list()
                    )
                end,
                { silent = true, desc = 'toggle harpoon menu' },
            },
            {
                '<leader>t',
                function()
                    require('harpoon.term').gotoTerminal()
                end,
                { silent = true, desc = 'go to terminal' },
            },
        },
        event = 'BufEnter',
        -- config = function()
        --     local harpoon = require('harpoon')
        --     local keymap = vim.keymap.set
        --     -- Harpoon file selection keybindings
        --     for i = 1, 4 do
        --         keymap(
        --             'n',
        --             '<C-'
        --                 .. (i == 1 and 'e' or (i == 2 and 'a' or (i == 3 and 'h' or 'i')))
        --                 .. '>',
        --             function()
        --                 harpoon:list():select(i)
        --             end,
        --             { silent = true, desc = 'navigate to harpoon file ' .. i }
        --         )
        --     end
        -- end,
    },
}
