return {
    {
        'npxbr/glow.nvim',
        config = function()
            local ok, glow = pcall(require, 'glow')
            if not ok then
                return
            end

            local glow_path = os.getenv('HOMEBREW_PREFIX')
                    and (os.getenv('HOMEBREW_PREFIX') .. '/bin/glow')
                or 'glow'

            glow.setup({
                glow_path = glow_path,
                install_path = glow_path,
                style = 'dark',
                border = 'shadow',
                pager = false,
                width_ratio = 0.7,
                height_ratio = 0.7,
            })
        end,
        keys = {
            {
                '<leader>mg',
                function()
                    local glow_bin = os.getenv('HOMEBREW_PREFIX')
                            and os.getenv('HOMEBREW_PREFIX') .. '/bin/glow'
                        or 'glow'

                    local function find_existing_glow_window()
                        for _, win in ipairs(vim.api.nvim_list_wins()) do
                            local buf = vim.api.nvim_win_get_buf(win)
                            local buf_name = vim.api.nvim_buf_get_name(buf)
                            if buf_name:find(glow_bin, 1, true) then
                                return win
                            end
                        end
                        return nil
                    end

                    -- Toggle: if already open, close it
                    local glow_window = find_existing_glow_window()
                    if glow_window then
                        vim.api.nvim_win_close(glow_window, true)
                        return
                    end

                    -- Validate initial file
                    local initial_fname = vim.fn.expand('%:p')
                    if initial_fname == '' or vim.bo.filetype ~= 'markdown' then
                        vim.notify('Open a .md file first', vim.log.levels.WARN)
                        return
                    end
                    if vim.fn.filereadable(initial_fname) ~= 1 then
                        vim.notify(
                            'File not found: ' .. initial_fname,
                            vim.log.levels.ERROR
                        )
                        return
                    end

                    local src_win = vim.api.nvim_get_current_win()
                    local preview_win
                    local preview_buf
                    local timer = vim.loop.new_timer()
                    local current_preview_file = initial_fname
                    local autocmd_group = vim.api.nvim_create_augroup(
                        'GlowPreview',
                        { clear = false }
                    )

                    -- Create split window
                    vim.cmd('vsplit')
                    preview_win = vim.api.nvim_get_current_win()

                    local function refresh(fname)
                        if not fname or fname == '' or vim.fn.filereadable(fname) ~= 1 then
                            return
                        end

                        if
                            not preview_win
                            or type(preview_win) ~= 'number'
                            or not vim.api.nvim_win_is_valid(preview_win)
                        then
                            return
                        end

                        current_preview_file = fname
                        local old_buf = preview_buf
                        local cur_win = vim.api.nvim_get_current_win()

                        vim.api.nvim_set_current_win(preview_win)
                        local new_buf = vim.api.nvim_create_buf(false, true)
                        vim.api.nvim_win_set_buf(preview_win, new_buf)

                        vim.fn.termopen({ glow_bin, '-s', 'dark', fname }, {
                            on_exit = function()
                                if vim.api.nvim_buf_is_valid(new_buf) then
                                    vim.bo[new_buf].modified = false
                                end
                            end,
                        })

                        vim.api.nvim_buf_set_option(new_buf, "scrollbind", false)
                        vim.wo[preview_win].cursorline = false
                        vim.wo[preview_win].number = false
                        vim.wo[preview_win].relativenumber = false
                        preview_buf = new_buf

                        if old_buf and vim.api.nvim_buf_is_valid(old_buf) and old_buf ~= new_buf then
                            pcall(vim.api.nvim_buf_delete, old_buf, { force = true })
                        end

                        if vim.api.nvim_win_is_valid(cur_win) then
                            vim.api.nvim_set_current_win(cur_win)
                        end
                    end

                    local function debounced_refresh(fname)
                        timer:stop()
                        timer:start(
                            100,
                            0,
                            vim.schedule_wrap(function()
                                refresh(fname)
                            end)
                        )
                    end

                    local function cleanup()
                        timer:stop()
                        timer:close()
                        if preview_buf and vim.api.nvim_buf_is_valid(preview_buf) then
                            pcall(vim.api.nvim_buf_delete, preview_buf, { force = true })
                        end
                        pcall(vim.api.nvim_del_augroup_by_name, 'GlowPreview')
                    end

                    -- Initial render
                    refresh(initial_fname)

                    -- Watch for buffer changes and saves
                    vim.api.nvim_create_autocmd(
                        { 'BufEnter', 'BufWritePost' },
                        {
                            group = autocmd_group,
                            pattern = '*.md',
                            callback = function(args)
                                local buf = args.buf
                                local fname = vim.api.nvim_buf_get_name(buf)

                                -- Skip if invalid file
                                if fname == '' or vim.fn.filereadable(fname) ~= 1 then
                                    return
                                end

                                -- Skip if not markdown
                                if vim.bo[buf].filetype ~= 'markdown' then
                                    return
                                end

                                -- Skip if we're in the preview window
                                local cur_win = vim.api.nvim_get_current_win()
                                if cur_win == preview_win then
                                    return
                                end

                                -- Update on file switch or save
                                if fname ~= current_preview_file or args.event == 'BufWritePost' then
                                    debounced_refresh(fname)
                                end
                            end,
                        }
                    )

                    -- Cleanup when preview window closes
                    vim.api.nvim_create_autocmd('WinClosed', {
                        group = autocmd_group,
                        pattern = tostring(preview_win),
                        once = true,
                        callback = cleanup,
                    })

                    vim.api.nvim_set_current_win(src_win)
                end,

                desc = 'Toggle live glow preview in vsplit',
            },
        },
    },
}

