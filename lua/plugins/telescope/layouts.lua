local M = {}

local Layout = require('telescope.pickers.layout')
local previewers = require('telescope.previewers')

local function map_range(
    input_start,
    input_end,
    output_start,
    output_end,
    input
)
    local input_length = input_end - input_start
    local output_length = output_end - output_start
    local max = math.max(output_start, output_end)
    local min = math.min(output_start, output_end)
    return math.min(
        max,
        math.max(
            min,
            output_start
                + ((input - input_start) / input_length) * output_length
        )
    )
end

local open_win = function(enter, width, height, row, col, title, border)
    local bufnr = vim.api.nvim_create_buf(false, true)
    local winid = vim.api.nvim_open_win(bufnr, enter, {
        style = 'minimal',
        relative = 'editor',
        width = width,
        height = height,
        row = row,
        col = col,
        border = border or 'solid',
        title = title and title or nil,
        title_pos = title and 'center' or nil,
    })

    return Layout.Window({
        bufnr = bufnr,
        winid = winid,
    })
end

local close_win = function(window)
    if window then
        if vim.api.nvim_win_is_valid(window.winid) then
            vim.api.nvim_win_close(window.winid, true)
        end
        if vim.api.nvim_buf_is_valid(window.bufnr) then
            vim.api.nvim_buf_delete(window.bufnr, { force = true })
        end
    end
end

local update_win = function(window, opts)
    if window then
        if vim.api.nvim_win_is_valid(window.winid) then
            vim.api.nvim_win_set_config(
                window.winid,
                vim.tbl_deep_extend(
                    'force',
                    vim.api.nvim_win_get_config(window.winid),
                    opts
                )
            )
        end
    end
end

M.bottom_pane = function(picker)
    local function get_configs()
        local hide_preview = vim.o.columns < 80
        local height = math.floor((vim.o.lines / 2) + 0.5) - 2
        local preview_ratio = map_range(80, 150, 3, 2, vim.o.columns)

        local preview_width = math.floor(vim.o.columns / preview_ratio) - 2
        local results_width = hide_preview and vim.o.columns
            or (math.floor(vim.o.columns - preview_width) - 3)

        local res = {}

        res.results = {
            width = results_width,
            height = height - 3,
            row = vim.o.lines - height,
            col = 0,
        }
        if not hide_preview then
            res.preview = {
                width = preview_width - 1,
                height = height - 1,
                row = vim.o.lines - height - 2,
                col = results_width + 2,
                border = {
                    '│',
                    ' ',
                    ' ',
                    ' ',
                    ' ',
                    ' ',
                    '│',
                    '│',
                },
            }
        end
        res.prompt = {
            width = results_width,
            height = 1,
            row = math.floor(vim.o.lines / 2),
            col = 0,
            border = {
                ' ',
                ' ',
                ' ',
                ' ',
                '─',
                '─',
                '─',
                ' ',
            },
        }
        return res
    end

    local layout = {}

    layout.picker = picker

    function layout:mount()
        local c = get_configs()
        self.results = open_win(
            false,
            c.results.width,
            c.results.height,
            c.results.row,
            c.results.col,
            picker.results_title
        )
        if c.preview then
            self.preview = open_win(
                false,
                c.preview.width,
                c.preview.height,
                c.preview.row,
                c.preview.col,
                picker.preview_title,
                c.preview.border
            )
        end
        self.prompt = open_win(
            true,
            c.prompt.width,
            c.prompt.height,
            c.prompt.row,
            c.prompt.col,
            picker.prompt_title,
            c.prompt.border
        )
    end

    function layout:update()
        local c = get_configs()
        update_win(self.results, c.results)
        if self.preview and c.preview then
            update_win(self.preview, c.preview)
        elseif c.preview and not self.preview then
            self.preview = open_win(
                false,
                c.preview.width,
                c.preview.height,
                c.preview.row,
                c.preview.col,
                picker.preview_title
            )
        elseif not c.preview and self.preview then
            close_win(self.preview)
            self.preview = nil
        end
        update_win(self.prompt, c.prompt)
    end

    function layout:unmount()
        close_win(self.results)
        if self.preview then
            close_win(self.preview)
        end
        close_win(self.prompt)
    end

    return Layout(layout)
end

M.vertical = function(picker)
    local function get_configs(enter, width, height, row, col, title)
        local win_config = {
            relative = 'editor',
            width = width,
            height = height,
            row = row,
            col = col,
            border = 'none',
        }
        if title ~= 'Preview' then
            win_config.style = 'minimal'
        end
        if title == 'Separator' then
            win_config.title = '---'
        end
        if title == 'Prompt' then
            win_config.border = {
                '─',
                '─',
                '─',
                '',
                '',
                '',
                '',
                '',
            }
        end
        return win_config
    end

    local function open_win(enter, width, height, row, col, title)
        local bufnr = vim.api.nvim_create_buf(false, true)
        local win_config = get_configs(enter, width, height, row, col, title)
        local winid = vim.api.nvim_open_win(bufnr, enter, win_config)

        vim.wo[winid].winhighlight = 'NormalFloat:TelescopeNormal'

        -- if title == "Separator" then
        --   -- Set content of separator
        --   vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { string.rep("─", width) })
        -- end

        return Layout.Window({
            bufnr = bufnr,
            winid = winid,
        })
    end

    local function destroy_window(window)
        if window then
            if vim.api.nvim_win_is_valid(window.winid) then
                vim.api.nvim_win_close(window.winid, true)
            end
            if vim.api.nvim_buf_is_valid(window.bufnr) then
                vim.api.nvim_buf_delete(window.bufnr, { force = true })
            end
        end
    end

    local update_window = function(window, opts)
        if window then
            if vim.api.nvim_win_is_valid(window.winid) then
                vim.api.nvim_win_set_config(
                    window.winid,
                    vim.tbl_deep_extend(
                        'force',
                        vim.api.nvim_win_get_config(window.winid),
                        opts
                    )
                )
            end
        end
    end

    local bufwidth = vim.api.nvim_get_option('columns')
    local bufheight = vim.api.nvim_get_option('lines')

    local preview_height = 20
    local preview_width = bufwidth - 2

    local prompt_height = 1
    local prompt_row = preview_height + 1
    local prompt_width = bufwidth

    local results_height = bufheight - preview_height - 4
    local results_row = prompt_row + prompt_height + 1
    local results_width = bufwidth - 2

    local separator

    local layout = Layout({
        picker = picker,
        mount = function(self)
            self.preview =
                open_win(false, preview_width, preview_height, 0, 0, 'Preview')
            separator =
                open_win(false, prompt_width, 1, preview_height, 0, 'Separator')
            self.prompt =
                open_win(true, prompt_width, 1, prompt_row, 0, 'Prompt')
            self.results = open_win(
                false,
                results_width,
                results_height,
                results_row,
                0,
                'Results'
            )
        end,
        unmount = function(self)
            destroy_window(self.results)
            destroy_window(self.preview)
            destroy_window(self.prompt)
            destroy_window(separator)
        end,
        update = function(self)
            local c = get_configs()
            update_window(self.results, c.results)
            update_window(self.preview, c.preview)
            update_window(self.prompt, c.prompt)
        end,
    })

    return layout
end

M.flexible = function(picker)
    local function get_configs()
        local width = math.min(math.floor(vim.o.columns / 6) * 5, 120)
        local height = math.floor((vim.o.lines / 3) + 0.5) * 2

        local preview_ratio = map_range(100, 150, 3, 2.2, vim.o.columns)
        -- map preview ratio from columns: map_range(input_start, input_end, output_start, output_end, input)

        if vim.o.columns > 120 then
            local row = math.floor((vim.o.lines / 2) - (height / 2))
            local col = math.floor((vim.o.columns / 2) - (width / 2))

            local preview_width = math.floor(width / preview_ratio) - 1
            local results_width = math.floor(width - preview_width)

            return {
                results = {
                    width = results_width,
                    height = height - 2,
                    row = row,
                    col = col,
                },
                preview = {
                    width = preview_width,
                    height = height,
                    row = row,
                    col = col + results_width + 2,
                    border = {
                        '│',
                        ' ',
                        ' ',
                        ' ',
                        ' ',
                        ' ',
                        '│',
                        '│',
                    },
                },
                prompt = {
                    width = results_width,
                    height = 1,
                    row = row + height - 1,
                    col = col,
                    border = {
                        '─',
                        '─',
                        '─',
                        ' ',
                        ' ',
                        ' ',
                        ' ',
                        ' ',
                    },
                },
            }
        else
            local row = math.floor((vim.o.lines / 2) - (height / 2))
            local col = math.floor((vim.o.columns / 2) - (width / 2))

            local hide_preview = false
            if vim.o.lines < 40 then
                hide_preview = true
            end

            local res = {}

            local results_height = (
                hide_preview and height or math.floor(height / 2)
            ) - 2
            res.results = {
                width = width,
                height = results_height,
                row = row + (hide_preview and 0 or math.floor(height / 2)),
                col = col,
            }
            res.prompt = {
                width = width,
                height = 1,
                row = row + height - 1,
                col = col,
            }
            if not hide_preview then
                res.preview = {
                    width = width,
                    height = math.floor(height / 2),
                    row = row - 2,
                    col = col,
                    border = {
                        ' ',
                        ' ',
                        ' ',
                        ' ',
                        '─',
                        '─',
                        '─',
                        ' ',
                    },
                }
            end
            return res
        end
    end

    local layout = {}

    layout.picker = picker

    function layout:mount()
        local c = get_configs()
        self.results = open_win(
            false,
            c.results.width,
            c.results.height,
            c.results.row,
            c.results.col,
            picker.results_title
        )
        if c.preview then
            self.preview = open_win(
                false,
                c.preview.width,
                c.preview.height,
                c.preview.row,
                c.preview.col,
                picker.preview_title,
                c.preview.border
            )
        end
        self.prompt = open_win(
            true,
            c.prompt.width,
            c.prompt.height,
            c.prompt.row,
            c.prompt.col,
            picker.prompt_title,
            c.prompt.border
        )
    end

    function layout:update()
        local c = get_configs()
        update_win(self.results, c.results)
        if self.preview and c.preview then
            update_win(self.preview, c.preview)
        elseif c.preview and not self.preview then
            self.preview = open_win(
                false,
                c.preview.width,
                c.preview.height,
                c.preview.row,
                c.preview.col,
                picker.preview_title or 'Preview'
            )
        elseif not c.preview and self.preview then
            close_win(self.preview)
            self.preview = nil
        end
        update_win(self.prompt, c.prompt)
    end

    function layout:unmount()
        close_win(self.results)
        close_win(self.preview)
        close_win(self.prompt)
    end

    return Layout(layout)
end

M.compact = function(picker)
    local function open_win(enter, width, height, row, col, title)
        local bufnr = vim.api.nvim_create_buf(false, true)
        local win_config = {
            style = 'minimal',
            relative = 'editor',
            width = width,
            height = height,
            row = row,
            col = col,
        }

        if title == 'Prompt' then
            win_config.border = {
                '',
                '',
                '',
                '│',
                '╯',
                '─',
                '╰',
                '│',
            }
        end
        -- add angles to the results
        if title == 'Results' then
            win_config.border = {
                '╭',
                '─',
                '╮',
                '│',
                '',
                '',
                '',
                '│',
            }
        end

        local winid = vim.api.nvim_open_win(bufnr, enter, win_config)
        vim.wo[winid].winhighlight = 'NormalFloat:TelescopeNormal'

        return Layout.Window({
            bufnr = bufnr,
            winid = winid,
        })
    end

    local prompt_autocmd_group = 'TelescopePrompt'
    vim.cmd('augroup ' .. prompt_autocmd_group)

    local function destroy_window(window)
        if window then
            if vim.api.nvim_win_is_valid(window.winid) then
                vim.api.nvim_win_close(window.winid, true)
            end
            if vim.api.nvim_buf_is_valid(window.bufnr) then
                vim.api.nvim_buf_delete(window.bufnr, { force = true })
            end
        end
    end

    local update_window = function(window, opts)
        if window then
            if vim.api.nvim_win_is_valid(window.winid) then
                vim.api.nvim_win_set_config(
                    window.winid,
                    vim.tbl_deep_extend(
                        'force',
                        vim.api.nvim_win_get_config(window.winid),
                        opts
                    )
                )
            end
        end
    end

    local bufwidth = vim.api.nvim_get_option('columns')
    local bufheight = vim.api.nvim_get_option('lines')
    local current_row, current_col =
        unpack(vim.api.nvim_win_get_cursor(vim.api.nvim_get_current_win()))

    local prompt_height = 1
    local prompt_row = math.floor(bufheight / 2) - 1
    local prompt_col = current_col + 7
    local prompt_width = bufwidth - prompt_col - 1

    local results_height = prompt_row - 1
    local results_row = 0
    local results_col = prompt_col
    local results_width = bufwidth - prompt_col - 1

    local layout = Layout({
        picker = picker,
        mount = function(self)
            self.prompt = open_win(
                true,
                prompt_width,
                prompt_height,
                prompt_row,
                prompt_col,
                'Prompt'
            )
            self.results = open_win(
                false,
                results_width,
                results_height,
                results_row,
                results_col,
                'Results'
            )
        end,
        unmount = function(self)
            destroy_window(self.results)
            destroy_window(self.preview)
            destroy_window(self.prompt)
        end,
        update = function(self) end,
    })

    return layout
end

M.live_grep = function(picker)
    local border_round =
        { '╭', '─', '╮', '│', '╯', '─', '╰', '│' }

    local function get_configs(
        enter,
        width,
        height,
        row,
        col,
        title,
        has_border
    )
        return {
            relative = 'editor',
            width = width,
            height = height,
            row = row,
            col = col,
            anchor = 'NW',
            border = has_border and border_round or 'none',
            style = 'minimal',
            noautocmd = false,
            title = title and tostring(title) or nil,
            title_pos = 'center',
        }
    end

    local function make_buf(name)
        local bufnr = vim.api.nvim_create_buf(false, true)
        vim.bo[bufnr].bufhidden = 'wipe'
        vim.bo[bufnr].buftype = 'nofile'
        vim.bo[bufnr].swapfile = false
        vim.bo[bufnr].modifiable = true
        if name and name ~= 'preview' then
            vim.bo[bufnr].filetype = name
        end
        return bufnr
    end

    local function open_window(
        enter,
        width,
        height,
        row,
        col,
        title,
        has_border
    )
        local name = title and title:lower():match('%w+') or nil
        local bufnr = make_buf(name)
        local win_config =
            get_configs(enter, width, height, row, col, title, has_border)
        local winid = vim.api.nvim_open_win(bufnr, enter, win_config)

        vim.wo[winid].winblend = 10
        vim.wo[winid].wrap = false
        vim.wo[winid].number = false
        vim.wo[winid].relativenumber = false

        if name == 'preview' then
            vim.wo[winid].cursorline = false
            vim.wo[winid].signcolumn = 'yes:2'
            vim.wo[winid].scrolloff = 8
            vim.wo[winid].winhighlight =
                'Normal:TelescopeNormal,NormalNC:TelescopeNormal'
        elseif name == 'results' then
            vim.wo[winid].cursorline = true
            vim.wo[winid].scrolloff = 999 -- Keep cursor centered
            vim.wo[winid].winhighlight =
                'Normal:TelescopeNormal,CursorLine:TelescopeSelection'
            vim.bo[bufnr].modifiable = false
        elseif name == 'prompt' then
            vim.wo[winid].cursorline = false
            vim.wo[winid].scrolloff = 0
            vim.wo[winid].winhighlight = 'Normal:TelescopePromptNormal'
        elseif title == 'Separator' then
            vim.wo[winid].cursorline = false
            vim.wo[winid].scrolloff = 0
            vim.wo[winid].winhighlight = 'Normal:TelescopeBorder'
            vim.api.nvim_buf_set_lines(
                bufnr,
                0,
                -1,
                false,
                { string.rep('─', math.max(1, width - 2)) }
            )
            vim.bo[bufnr].modifiable = false
        end

        return Layout.Window({ bufnr = bufnr, winid = winid })
    end

    local function close_window(window)
        if not window then
            return
        end
        if window.winid and vim.api.nvim_win_is_valid(window.winid) then
            pcall(vim.api.nvim_win_close, window.winid, true)
        end
        if window.bufnr and vim.api.nvim_buf_is_valid(window.bufnr) then
            pcall(vim.api.nvim_buf_delete, window.bufnr, { force = true })
        end
    end

    local function update_window(window, opts)
        if
            not window
            or not window.winid
            or not vim.api.nvim_win_is_valid(window.winid)
        then
            return
        end
        local ok, cur = pcall(vim.api.nvim_win_get_config, window.winid)
        if not ok then
            return
        end
        local merged = vim.tbl_deep_extend('force', cur, opts)
        pcall(vim.api.nvim_win_set_config, window.winid, merged)
    end

    local function compute_layout()
        local margin_x, margin_y = 0, 0 -- 0 for max width
        local total_w = math.max(20, vim.o.columns - margin_x * 2)
        local total_h = math.max(6, vim.o.lines - margin_y * 2)

        local results_w = math.floor(total_w * 0.45)
        local preview_w = total_w - results_w - 1
        local prompt_h = 1
        local prompt_w = math.max(30, math.floor(total_w * 0.6))

        local results = {
            width = results_w,
            height = total_h - prompt_h - 2,
            row = margin_y,
            col = margin_x,
        }
        local preview = {
            width = preview_w,
            height = results.height + 1,
            row = margin_y,
            col = margin_x + results_w + 1,
        }
        local separator = {
            width = total_w,
            height = 1,
            row = margin_y + results.height,
            col = margin_x,
        }
        local prompt = {
            width = prompt_w,
            height = prompt_h,
            row = margin_y + results.height + 1,
            col = margin_x + math.floor((total_w - prompt_w) / 2),
        }

        return results, preview, separator, prompt
    end

    local resize_au_id

    return Layout({
        picker = picker,
        mount = function(self)
            local results_cfg, preview_cfg, sep_cfg, prompt_cfg =
                compute_layout()

            self.results = open_window(
                false,
                results_cfg.width,
                results_cfg.height,
                results_cfg.row,
                results_cfg.col,
                picker.results_title or 'Results',
                true
            )
            self.preview = open_window(
                false,
                preview_cfg.width,
                preview_cfg.height,
                preview_cfg.row,
                preview_cfg.col,
                picker.preview_title or 'Preview',
                true
            )
            self.separator = open_window(
                false,
                sep_cfg.width,
                sep_cfg.height,
                sep_cfg.row,
                sep_cfg.col,
                'Separator',
                false
            )
            self.prompt = open_window(
                true,
                prompt_cfg.width,
                prompt_cfg.height,
                prompt_cfg.row,
                prompt_cfg.col,
                picker.prompt_title or 'Prompt',
                true
            )

            -- Maintain scrolloff even if Telescope tries to override
            if self.results and self.results.winid then
                vim.api.nvim_create_autocmd('CursorMoved', {
                    buffer = self.results.bufnr,
                    callback = function()
                        if vim.api.nvim_win_is_valid(self.results.winid) then
                            pcall(function()
                                vim.wo[self.results.winid].scrolloff = 999
                            end)
                        end
                    end,
                })
            end

            resize_au_id = vim.api.nvim_create_autocmd('VimResized', {
                callback = function()
                    pcall(function()
                        if self and self.update then
                            self:update()
                        end
                    end)
                end,
            })
        end,
        unmount = function(self)
            if resize_au_id then
                pcall(vim.api.nvim_del_autocmd, resize_au_id)
                resize_au_id = nil
            end
            close_window(self.results)
            close_window(self.preview)
            close_window(self.separator)
            close_window(self.prompt)
        end,
        update = function(self)
            local results_cfg, preview_cfg, sep_cfg, prompt_cfg =
                compute_layout()

            if self.results then
                update_window(
                    self.results,
                    get_configs(
                        false,
                        results_cfg.width,
                        results_cfg.height,
                        results_cfg.row,
                        results_cfg.col,
                        picker.results_title or 'Results',
                        true
                    )
                )
                -- Re-enforce scrolloff after resize
                if vim.api.nvim_win_is_valid(self.results.winid) then
                    pcall(function()
                        vim.wo[self.results.winid].scrolloff = 999
                    end)
                end
            end
            if self.preview then
                update_window(
                    self.preview,
                    get_configs(
                        false,
                        preview_cfg.width,
                        preview_cfg.height,
                        preview_cfg.row,
                        preview_cfg.col,
                        picker.preview_title or 'Preview',
                        true
                    )
                )
            end
            if self.separator then
                update_window(
                    self.separator,
                    get_configs(
                        false,
                        sep_cfg.width,
                        sep_cfg.height,
                        sep_cfg.row,
                        sep_cfg.col,
                        'Separator',
                        false
                    )
                )
                if
                    self.separator.bufnr
                    and vim.api.nvim_buf_is_valid(self.separator.bufnr)
                then
                    vim.bo[self.separator.bufnr].modifiable = true
                    vim.api.nvim_buf_set_lines(
                        self.separator.bufnr,
                        0,
                        -1,
                        false,
                        { string.rep('─', math.max(1, sep_cfg.width - 2)) }
                    )
                    vim.bo[self.separator.bufnr].modifiable = false
                end
            end
            if self.prompt then
                update_window(
                    self.prompt,
                    get_configs(
                        true,
                        prompt_cfg.width,
                        prompt_cfg.height,
                        prompt_cfg.row,
                        prompt_cfg.col,
                        picker.prompt_title or 'Prompt',
                        true
                    )
                )
            end
        end,
    })
end

M.test = function()
    vim.cmd('lua package.loaded["plugins.telescope.layouts"] = nil')
    vim.cmd('lua package.loaded["telescope"] = nil')
    require('telescope.builtin').find_files({
        create_layout = M.compact,
        layout_config = {},
    })
end

return M
