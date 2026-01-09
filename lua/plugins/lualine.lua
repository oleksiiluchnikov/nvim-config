return {
    {
        -- [lualine.nvim](https://github.com/nvim-lualine/lualine.nvim)
        -- Creates a light and configurable status line for Neovim
        -----------------------------------------------------------------------
        'nvim-lualine/lualine.nvim',
        dependencies = {
            'piersolenski/wtf.nvim',
            'lewis6991/gitsigns.nvim',
            -- navic
            'SmiteshP/nvim-navic',
        },
        opts = {
            options = {
                icons_enabled = false,
                theme = 'catppuccin',
                component_separators = { left = '', right = '' },
                section_separators = { left = '', right = '' },
                disabled_filetypes = {
                    statusline = {},
                    winbar = {},
                },
                ignore_focus = {},
                always_divide_middle = true,
                globalstatus = false,
                refresh = {
                    statusline = 1000,
                    tabline = 1000,
                    winbar = 1000,
                },
            },
            sections = {
                lualine_a = {
                    {
                        'mode',
                        fmt = function(str)
                            return str
                        end,
                    },
                },
                lualine_b = {
                    -- full cwd
                    function()
                        return vim.fn.getcwd()
                    end,
                    {
                        'branch',
                        icon = '󰘬',
                    },
                    {
                        'diff',
                        symbols = {
                            added = '+',
                            modified = '~',
                            removed = '-',
                        },
                        source = function()
                            local gitsigns = vim.b.gitsigns_status_dict
                            if gitsigns then
                                return {
                                    added = gitsigns.added,
                                    modified = gitsigns.changed,
                                    removed = gitsigns.removed,
                                }
                            end
                        end,
                    },
                    {
                        'diagnostics',
                        sources = { 'nvim_diagnostic' },
                        sections = { 'error', 'warn', 'info', 'hint' },
                        symbols = {
                            error = '',
                            warn = '',
                            info = '',
                            hint = '',
                        },
                        update_in_insert = true,
                    },
                },
                lualine_c = {
                    {
                        'filename',
                        path = 1,
                        symbols = {
                            modified = '*',
                            readonly = '',
                            unnamed = '[No Name]',
                        },
                    },
                },
                lualine_x = {
                    {
                        function()
                            local adapter = vim.g.codecompanion_initial_adapter
                            if adapter then
                                return adapter
                            end
                        end,
                    },
                    -- Filetype
                    { 'filetype', colored = true },
                },
                lualine_y = {
                    -- Current function/method
                    {
                        function()
                            local navic = require('nvim-navic')
                            if navic.is_available() then
                                local location = navic.get_location()
                                return location ~= '' and location or ''
                            end
                            return ''
                        end,
                        cond = function()
                            local navic = require('nvim-navic')
                            return package.loaded['nvim-navic']
                                and navic.is_available()
                        end,
                    },
                },
                lualine_z = {
                    -- Location in file
                    {
                        'location',
                        fmt = function()
                            local line = vim.fn.line('.')
                            local total_lines = vim.fn.line('$')
                            return string.format(
                                '%d/%d:%-2d',
                                line,
                                total_lines,
                                vim.fn.col('.')
                            )
                        end,
                    },
                    -- Progress percentage
                    {
                        'progress',
                        fmt = function(str)
                            return str .. ' '
                        end,
                    },
                },
            },
            inactive_sections = {
                lualine_a = {},
                lualine_b = {},
                lualine_c = { { 'filename', path = 1 } },
                lualine_x = {},
                lualine_y = {
                    'location',
                },
                lualine_z = {},
            },
            tabline = {},
            winbar = {},
            inactive_winbar = {},
            extensions = {},
        },
    },
}
