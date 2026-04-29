return {
    {
        -- [formatter.nvim](https://github.com/mhartington/formatter.nvim)
        -- Code formatter
        -----------------------------------------------------------------------
        'mhartington/formatter.nvim',
        config = function()
            local function get_pi_nvim_mode_draft_root()
                local explicit = vim.env.PI_NVIM_MODE_DRAFT_DIR
                if explicit and explicit ~= '' then
                    return vim.fs.normalize(explicit)
                end

                local pi_state_dir = vim.env.PI_STATE_DIR
                if pi_state_dir and pi_state_dir ~= '' then
                    return vim.fs.normalize(vim.fs.joinpath(pi_state_dir, 'nvim-mode'))
                end

                local xdg_state_home = vim.env.XDG_STATE_HOME
                local state_home = (xdg_state_home and xdg_state_home ~= '')
                        and xdg_state_home
                    or vim.fs.joinpath(vim.env.HOME, '.local', 'state')
                return vim.fs.normalize(
                    vim.fs.joinpath(state_home, 'pi', 'nvim-mode')
                )
            end

            local function is_pi_nvim_mode_draft(bufnr)
                local name = vim.api.nvim_buf_get_name(bufnr)
                if name == '' then
                    return false
                end

                local normalized = vim.fs.normalize(name)
                local draft_root = get_pi_nvim_mode_draft_root()
                if normalized == draft_root then
                    return true
                end
                return normalized:sub(1, #draft_root + 1) == draft_root .. '/'
            end

            local function should_skip_auto_format(bufnr)
                if not vim.api.nvim_buf_is_valid(bufnr) then
                    return true
                end
                if vim.bo[bufnr].buftype ~= '' or not vim.bo[bufnr].modifiable then
                    return true
                end
                if is_pi_nvim_mode_draft(bufnr) then
                    return true
                end
                return false
            end

            local opts = {
                logging = false,
                log_level = vim.log.levels.WARN,
                filetype = {
                    lua = {
                        require('formatter.filetypes.lua').stylua,
                        function()
                            -- Supports conditional formatting
                            if
                                require('formatter.util').get_current_buffer_file_name()
                                == 'special.lua'
                            then
                                return nil
                            end

                            return {
                                exe = 'stylua',
                                args = {
                                    '--search-parent-directories',
                                    '--stdin-filepath',
                                    require('formatter.util').escape_path(
                                        require('formatter.util').get_current_buffer_file_path()
                                    ),
                                    '--',
                                    '-',
                                },
                                stdin = true,
                            }
                        end,
                    },
                    python = {
                        require('formatter.filetypes.python').black,
                        function()
                            return {
                                exe = 'black',
                                args = { '-' },
                                stdin = true,
                            }
                        end,
                    },
                    markdown = {
                        function(parser)
                            if not parser then
                                return {
                                    exe = 'prettier',
                                    args = {
                                        '--stdin-filepath',
                                        require('formatter.util').escape_path(
                                            require('formatter.util').get_current_buffer_file_path()
                                        ),
                                    },
                                    stdin = true,
                                    try_node_modules = true,
                                }
                            end

                            return {
                                exe = 'prettier',
                                args = {
                                    '--stdin-filepath',
                                    require('formatter.util').escape_path(
                                        require('formatter.util').get_current_buffer_file_path()
                                    ),
                                    '--parser',
                                    parser,
                                },
                                stdin = true,
                                try_node_modules = true,
                            }
                        end,
                    },
                    rust = {
                        function()
                            return {
                                exe = 'rustfmt',
                                args = {
                                    '--emit=stdout',
                                    '--edition=2021',
                                },
                                stdin = true,
                            }
                        end,
                    },

                    ['*'] = {
                        require('formatter.filetypes.any').remove_trailing_whitespace,
                    },
                },
            }
            require('formatter').setup(opts)
            local augroup_formatter =
                vim.api.nvim_create_augroup('__formatter__', {
                    clear = true,
                })

            vim.api.nvim_create_autocmd('BufWritePre', {
                pattern = '*',
                callback = function(args)
                    if should_skip_auto_format(args.buf) then
                        return
                    end
                    pcall(vim.api.nvim_exec2, 'Format', {})
                end,
                group = augroup_formatter,
            })
        end,
    },
}
