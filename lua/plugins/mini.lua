return {
    {
        -- [mini.indentscope](https://github.com/echasnovski/mini.indentscope)
        -- Adds indentation guides to Neovim
        -----------------------------------------------------------------------
        'echasnovski/mini.indentscope',
        version = false, -- wait till new 0.7.0 release to put it back on semver
        event = 'BufRead',
        opts = {
            -- symbol = "▏",
            symbol = '│',
            options = { try_as_border = true },
        },
        init = function()
            vim.api.nvim_create_autocmd('FileType', {
                pattern = {
                    'alpha',
                    'dashboard',
                    'fzf',
                    'help',
                    'lazy',
                    'lazyterm',
                    'mason',
                    'neo-tree',
                    'notify',
                    'toggleterm',
                    'Trouble',
                    'trouble',
                },
                callback = function()
                    ---@diagnostic disable-next-line: inject-field
                    vim.b.miniindentscope_disable = true
                end,
            })
        end,
    },
    {
        'echasnovski/mini.test',
        version = false,
        lazy = true, -- only loaded when running tests or explicitly required
        config = function()
            require('mini.test').setup()
        end,
    },
}
