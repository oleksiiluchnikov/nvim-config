return {
    {
        -- [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim)
        -- Fuzzy finder with a rich plugin ecosystem
        -- TODO:Review configurtation
        -----------------------------------------------------------------------
        'nvim-telescope/telescope.nvim',
        dependencies = {
            'nvim-lua/plenary.nvim',
            'benfowler/telescope-luasnip.nvim',
        },
        -- config = function()
        --     require('plugins.telescope')
        -- end,
        lazy = false,
        opts = function(opts)
            local telescope = require('telescope')
            local actions = require('telescope.actions')
            local custom_actions = require('plugins.telescope.actions')
            ---@see telescope.setup.defaults
            local defaults = {
                sorting_strategy = 'ascending',
                selection_strategy = 'closest', -- "reset", "row", "closest". "closest" is the default.
                cycle_layout_list = {
                    'bottom_panel',
                    'center',
                    'cursor',
                    'horizontal',
                    'vertical',
                },

                winblend = 0,
                wrap_results = false,
                prompt_prefix = '', -- " ", -- " ", -- " ",
                selection_caret = '',
                entry_prefix = '',
                multi_icon = '...',
                initial_mode = 'insert',
                border = true,
                path_display = { 'absolute' },
                dynamic_title_preview = true,
                results_title = 'Results',
                prompt_title = function()
                    return require('config.utils.directory').get_root_dir()
                end,
                mappings = {
                    i = {
                        -- ["<esc>"] to go to normal mode
                        ['<esc>'] = function()
                            vim.cmd([[stopinsert]])
                        end,
                        ['<C-A>'] = function(prompt_bufnr)
                            custom_actions.multi_selection_open(prompt_bufnr)
                        end,
                        ['<C-h>'] = custom_actions.send_selected_to_harpoon,
                    },
                    n = {
                        ['q'] = actions.close,
                        ['<esc>'] = actions.close,
                        ['<C-A>'] = function(prompt_bufnr)
                            custom_actions.multi_selection_open(prompt_bufnr)
                        end,
                    },
                },
                preview = {
                    check_mime_type = true,
                    filesize_limit = 5000000, -- 5000000 bytes = 5MB
                    timeoutlen = 1000,
                    treesitter = true,
                    msg_bg_fillchar = ' ',
                },
                vimgrep_arguments = {
                    'rg',
                    '--color=never',
                    '--no-heading',
                    '--with-filename',
                    '--line-number',
                    '--column',
                    '--smart-case',
                },
                set_env = { ['COLORTERM'] = 'truecolor' },
                color_devicons = true,
                dynamic_preview_title = true,
            }

            local extensions_opts = {
                file_browser = {
                    sorting_strategy = 'ascending',
                    hidden = true,
                    mappings = {
                        i = {
                            ['<C-h>'] = custom_actions.send_selected_to_harpoon,
                        },
                    },
                },
                ['ui-select'] = {
                    require('telescope.themes').get_cursor(),
                },
                fzf = {
                    fuzzy = true,
                    override_file_sorter = true,
                    case_mode = 'smart_case',
                },
                -- bookmarks = {
                --     selected_browser = "google-chrome",
                --     url_open_command = "open",
                -- },
                zoxide = {
                    prompt_title = 'Zoxide',
                    cwd = '~/.config/nvim',
                },
                repo = {
                    prompt_title = 'Repos',
                    cwd = '~/.config/nvim',
                },
                neoclip = {
                    preview = false,
                    shorten_path = false,
                },
                gh = {
                    layout_config = {
                        prompt_position = 'top',
                    },
                },
                textcase = {
                    prompt_title = 'Text Case',
                },
                notify = {
                    position = 'top',
                    theme = 'cursor',
                },
                media_files = {
                    filetypes = { 'png', 'webp', 'jpg', 'jpeg' },
                    find_cmd = 'fd',
                },
                configs = {
                    prompt_title = 'Configs',
                    cwd = '~/.config/nvim',
                },
            }

            ---Extensions
            ---@see telescope.load_extension
            local extensions = {
                'file_browser',
                'fzf',
                'bookmarks',
                'zoxide',
                'neoclip',
                'gh',
                'textcase',
                'notify',
                'media_files',
                'repo',
                'ui-select',
                'harpoon',
                'nerdy',
                'configs',
                'avante',
                'vault',
                'prompts',
                'llm_models',
                'luasnip',
            }

            for _, ext in ipairs(extensions) do
                local ok, err = pcall(require('telescope').load_extension, ext)
                if not ok then
                    error('Error loading ' .. ext .. '\n\n' .. err)
                end
            end

            opts = telescope.setup({
                defaults = defaults,
                extensions = extensions_opts,
            })

            require('plugins.telescope.pickers')
            return opts
        end,
    },
}
