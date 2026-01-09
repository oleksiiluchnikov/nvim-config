local M = {}

-- Cache frequently used modules
local actions = require('telescope.actions')
local actions_state = require('telescope.actions.state')
local builtin = require('telescope.builtin')
local themes = require('telescope.themes')
local pickers = require('telescope.pickers')
local finders = require('telescope.finders')
local make_entry = require('telescope.make_entry')
local conf = require('telescope.config').values
local previewers = require('telescope.previewers')

-- Local references
local layouts = require('plugins.telescope.layouts')
local dir_utils = require('config.utils.directory')

-- Entry makers
local entry_makers = {
    gen_from_live_grep = make_entry.gen_from_vimgrep({}),
}

-- ============================================================================
-- Helper Functions
-- ============================================================================

--- Get vertical layout configuration
---@return table
local function get_vertical_layout()
    return {
        layout_strategy = 'vertical',
        layout_config = {
            mirror = true,
            prompt_position = 'top',
            preview_height = 0.5,
        },
    }
end

--- Get help tags layout configuration
---@return table
local function get_help_layout()
    return {
        layout_strategy = 'vertical',
        layout_config = {
            height = 0.9,
            mirror = false,
            prompt_position = 'top',
            preview_height = 0.8,
        },
    }
end

--- Get horizontal layout configuration
---@return table
local function get_horizontal_layout()
    return {
        layout_strategy = 'horizontal',
        layout_config = {
            width = 0.9,
            height = 0.9,
            prompt_position = 'top',
            preview_cutoff = 120,
            preview_width = 0.65,
        },
    }
end

--- Get standard live grep options
---@param search_dirs table
---@param opts? table
---@return table
local function get_live_grep_opts(search_dirs, opts)
    opts = opts or {}
    return vim.tbl_extend('force', {
        hidden = false,
        follow = true,
        search_dirs = search_dirs,
        create_layout = layouts.live_grep,
        entry_maker = entry_makers.gen_from_live_grep,
        path_display = { 'smart' },
    }, opts)
end

--- Find project root directory
---@return string|nil
function M.find_project_root()
    return dir_utils.get_root_dir()
end

-- ============================================================================
-- Core Picker Functions
-- ============================================================================

--- Choose a telescope picker
---@usage :lua require('plugins.telescope.custom_pickers').choose_picker()
function M.choose_picker()
    local root_dir = dir_utils.get_root_dir()
    builtin.builtin({
        cwd = root_dir,
        hidden = false,
        follow = true,
        search_dirs = { root_dir },
        create_layout = layouts.compact,
    })
end

--- Open a file in the current working directory
---@usage :lua require('plugins.telescope.custom_pickers').open_file_in_workspace()
function M.open_file_in_workspace()
    local root_dir = dir_utils.get_root_dir()
    builtin.find_files(vim.tbl_extend('force', {
        cwd = root_dir,
        hidden = false,
        follow = true,
        search_dirs = { root_dir },
    }, get_vertical_layout()))
end

--- Open a file from home directory
---@usage :lua require('plugins.telescope.custom_pickers').open_file_from_home()
function M.open_file_from_home()
    builtin.find_files(vim.tbl_extend('force', {
        cwd = '~',
        hidden = false,
        follow = true,
        find_command = {
            'fd',
            '--type',
            'f',
            '--hidden',
            '--follow',
            '--exclude',
            'node_modules',
            '--max-depth',
            '3',
        },
        search_dirs = { '~' },
    }, get_vertical_layout()))
end

--- Open a file path from typing
---@usage :lua require('plugins.telescope.custom_pickers').open_path()
function M.open_path()
    builtin.find_files(themes.get_dropdown(vim.tbl_extend('force', {
        cwd = '~',
        hidden = true,
        follow = true,
        search_dirs = { '~' },
    }, get_vertical_layout())))
end

-- ============================================================================
-- Grep Functions
-- ============================================================================

-- ============================================================================
-- Grep Functions
-- ============================================================================

-- ============================================================================
-- Grep Functions
-- ============================================================================

-- ============================================================================
-- Grep Functions
-- ============================================================================

--- Grep across the current working directory with advanced filtering capabilities
--- @param opts? table<string,any>
--- @field cwd? string
--- @field default_text? string
--- @field additional_args? string[]
function M.grep_across_workspace(opts)
    opts = opts or {}
    opts.cwd = opts.cwd or dir_utils.get_root_dir()

    local has_devicons, devicons = pcall(require, 'nvim-web-devicons')
    local finders = require('telescope.finders')
    local previewers = require('telescope.previewers')
    local pickers = require('telescope.pickers')
    local actions = require('telescope.actions')
    local make_entry = require('telescope.make_entry')
    local conf = require('telescope.config').values

    local additional_args = opts.additional_args or {}
    local base_args = {
        '--color=never',
        '--no-heading',
        '--with-filename',
        '--line-number',
        '--column',
        '--smart-case',
        '--hidden',
        '--glob=!.git/',
        '--glob=!node_modules/',
        '--trim',
    }
    local current_search_term = ''
    local preview_timer = nil
    local ns_hl = vim.api.nvim_create_namespace('telescope_grep_hl')
    local ns_virt = vim.api.nvim_create_namespace('telescope_grep_virt')

    local hl_groups = {
        {
            'TelescopeGrepMatch',
            { fg = '#ff007c', bg = '#3d1f2e', bold = false },
        },
        {
            'TelescopeGrepMatchBg',
            { bg = '#2d1b2e', fg = '#ff66a3', bold = false },
        },
        { 'TelescopeGrepBorder', { fg = '#7aa2f7', bold = false } },
        {
            'TelescopeGrepCurrentMatch',
            { bg = '#4d2a3e', fg = '#ffffff', bold = true, underline = true },
        },
        { 'TelescopeGrepLineNr', { fg = '#565f89', italic = true } },
        { 'TelescopeGrepPath', { fg = '#7dcfff', italic = true } },
        { 'TelescopeGrepIcon', { fg = '#bb9af7' } },
        { 'TelescopeGrepDimmed', { fg = '#3b4261' } },
        { 'TelescopeGrepTargetLine', { bg = '#1f1f2e', bold = false } },
        { 'TelescopeGrepBox', { fg = '#7aa2f7', bold = false } },
        {
            'TelescopeGrepMatchCount',
            { fg = '#9ece6a', bg = '#1a2b1a', bold = false },
        },
        { 'TelescopeGrepContext', { fg = '#787c99' } },
        { 'TelescopeGrepMatchLineNr', { fg = '#ff9e64', bold = false } },
        {
            'TelescopeGrepTargetLineNr',
            { fg = '#ff007c', bg = '#2d1b2e', bold = false },
        },
        { 'TelescopeGrepIndentGuide', { fg = '#2a2a3a' } },
        { 'TelescopeGrepContextLine', { bg = '#15151f' } },
    }
    for _, hl in ipairs(hl_groups) do
        vim.api.nvim_set_hl(0, hl[1], hl[2])
    end

    local custom_entry_maker = function(opts_inner)
        local displayer = require('telescope.pickers.entry_display').create({
            separator = '  ',
            items = {
                { width = 1 },
                { width = 28 },
                { width = 4 },
                -- { width = 3 },
                { width = 2 },
                { remaining = true },
            },
        })

        local make_display = function(entry)
            local filename = vim.fn.fnamemodify(entry.filename, ':t')
            local dir = vim.fn
                .fnamemodify(entry.filename, ':h')
                :gsub(vim.pesc(opts.cwd or vim.fn.getcwd()) .. '/', '')
            local display_path = (
                dir ~= '' and dir ~= '.' and (dir .. '/') or ''
            ) .. filename

            local icon, icon_hl = '󰈔', 'TelescopeGrepIcon'
            if has_devicons then
                local ic, hl = devicons.get_icon(
                    filename,
                    vim.fn.fnamemodify(filename, ':e'),
                    { default = true }
                )
                icon, icon_hl = ic or icon, hl or icon_hl
            end

            local text_display, highlights = entry.text, {}
            if current_search_term ~= '' then
                local term = current_search_term:gsub('^regex:', '')
                if not current_search_term:match('^regex:') then
                    local pattern_lower, text_lower =
                        term:lower(), text_display:lower()
                    local idx = 1
                    while idx <= #text_display do
                        local s, e = text_lower:find(pattern_lower, idx, true)
                        if not s then
                            break
                        end
                        table.insert(
                            highlights,
                            { { s - 1, e }, 'TelescopeGrepMatch' }
                        )
                        idx = e + 1
                    end
                end
            end

            return displayer({
                { icon, icon_hl },
                { display_path, 'TelescopeGrepPath' },
                { tostring(entry.lnum), 'TelescopeGrepLineNr' },
                -- { ':' .. tostring(entry.col), 'Comment' },
                { '│', 'TelescopeGrepBorder' },
                {
                    text_display,
                    function()
                        return highlights
                    end,
                },
            })
        end

        local base = make_entry.gen_from_vimgrep(opts_inner)
        return function(line)
            local entry = base(line)
            if entry then
                entry.display = make_display
            end
            return entry
        end
    end

    local apply_styling
    apply_styling = function(bufnr, winid, entry, attempt)
        attempt = attempt or 1
        if
            not (
                vim.api.nvim_buf_is_valid(bufnr)
                and vim.api.nvim_win_is_valid(winid)
            )
        then
            return
        end

        local lnum = entry.lnum or 1
        local line_count = vim.api.nvim_buf_line_count(bufnr)

        -- Check if buffer is actually populated (not just created)
        if line_count < 3 or lnum > line_count then
            if attempt < 8 then
                vim.defer_fn(function()
                    apply_styling(bufnr, winid, entry, attempt + 1)
                end, 20 * attempt)
            end
            return
        end

        -- Additional check: try to read a line to verify content
        local ok, test_line =
            pcall(vim.api.nvim_buf_get_lines, bufnr, lnum - 1, lnum, false)
        if not ok or not test_line or #test_line == 0 or test_line[1] == '' then
            if attempt < 8 then
                vim.defer_fn(function()
                    apply_styling(bufnr, winid, entry, attempt + 1)
                end, 20 * attempt)
            end
            return
        end

        pcall(function()
            vim.wo[winid].cursorline = true
            vim.wo[winid].cursorlineopt = 'both'
            vim.wo[winid].number = true
            vim.wo[winid].relativenumber = false
            vim.wo[winid].scrolloff = 8
            vim.wo[winid].signcolumn = 'yes:2'
            vim.wo[winid].wrap = false
            vim.bo[bufnr].list = false
        end)

        vim.api.nvim_buf_clear_namespace(bufnr, ns_hl, 0, -1)
        vim.api.nvim_buf_clear_namespace(bufnr, ns_virt, 0, -1)

        if current_search_term == '' then
            pcall(function()
                vim.api.nvim_win_set_cursor(winid, { lnum, 0 })
                vim.api.nvim_win_call(winid, function()
                    vim.cmd('normal! zz')
                end)
            end)
            return
        end

        local term = current_search_term:gsub('^regex:', '')
        local is_regex = current_search_term:match('^regex:')
        local scan_radius = 40
        local top = math.max(0, lnum - scan_radius)
        local bot = math.min(line_count, lnum + scan_radius)
        local lines = vim.api.nvim_buf_get_lines(bufnr, top, bot, false)

        local match_lines, total_matches = {}, 0

        for i, line in ipairs(lines) do
            local row = top + i - 1
            local is_target = (row + 1 == lnum)
            local match_count = 0
            local distance = math.abs(row + 1 - lnum)

            if is_regex then
                local regex_ok, regex = pcall(vim.regex, term)
                if regex_ok and regex then
                    local offset = 0
                    while offset < #line do
                        local s, e = regex:match_str(line:sub(offset + 1))
                        if not s then
                            break
                        end
                        match_count = match_count + 1
                        local hl = is_target and 'TelescopeGrepCurrentMatch'
                            or 'TelescopeGrepMatchBg'
                        pcall(
                            vim.api.nvim_buf_add_highlight,
                            bufnr,
                            ns_hl,
                            hl,
                            row,
                            offset + s,
                            offset + e
                        )
                        offset = offset + e
                        if e == 0 then
                            break
                        end
                    end
                end
            else
                local pattern_lower, line_lower = term:lower(), line:lower()
                local idx = 1
                while idx <= #line do
                    local s, e = line_lower:find(pattern_lower, idx, true)
                    if not s then
                        break
                    end
                    match_count = match_count + 1
                    local hl = is_target and 'TelescopeGrepCurrentMatch'
                        or 'TelescopeGrepMatchBg'
                    pcall(
                        vim.api.nvim_buf_add_highlight,
                        bufnr,
                        ns_hl,
                        hl,
                        row,
                        s - 1,
                        e
                    )
                    idx = e + 1
                end
            end

            if match_count > 0 then
                table.insert(
                    match_lines,
                    { row = row, count = match_count, is_target = is_target }
                )
                total_matches = total_matches + match_count
            end

            if is_target then
                pcall(
                    vim.api.nvim_buf_add_highlight,
                    bufnr,
                    ns_hl,
                    'TelescopeGrepTargetLine',
                    row,
                    0,
                    -1
                )
                pcall(vim.api.nvim_buf_set_extmark, bufnr, ns_virt, row, 0, {
                    number_hl_group = 'TelescopeGrepTargetLineNr',
                    line_hl_group = 'TelescopeGrepTargetLine',
                    priority = 300,
                })
            elseif match_count > 0 then
                pcall(vim.api.nvim_buf_set_extmark, bufnr, ns_virt, row, 0, {
                    number_hl_group = 'TelescopeGrepMatchLineNr',
                    priority = 250,
                })
            elseif distance > 5 then
                pcall(
                    vim.api.nvim_buf_add_highlight,
                    bufnr,
                    ns_hl,
                    'TelescopeGrepDimmed',
                    row,
                    0,
                    -1
                )
                -- elseif distance <= 3 then
                --     pcall(
                --         vim.api.nvim_buf_add_highlight,
                --         bufnr,
                --         ns_hl,
                --         'TelescopeGrepContextLine',
                --         row,
                --         0,
                --         -1
                --     )
            end

            local indent = line:match('^%s*')
            if indent and #indent > 1 then
                for col = 0, #indent - 1, 2 do
                    pcall(
                        vim.api.nvim_buf_set_extmark,
                        bufnr,
                        ns_virt,
                        row,
                        col,
                        {
                            virt_text = {
                                { '│', 'TelescopeGrepIndentGuide' },
                            },
                            virt_text_pos = 'overlay',
                            priority = 100,
                        }
                    )
                end
            end
        end

        local max_decorations = 25
        local decoration_count = math.min(#match_lines, max_decorations)
        for idx = 1, decoration_count do
            local m = match_lines[idx]
            local sign_text = m.is_target and '▶'
                or (m.count > 3 and '●●' or '●')
            local sign_hl = m.is_target and 'TelescopeGrepCurrentMatch'
                or 'TelescopeGrepMatch'

            pcall(vim.api.nvim_buf_set_extmark, bufnr, ns_virt, m.row, 0, {
                sign_text = sign_text,
                sign_hl_group = sign_hl,
                priority = m.is_target and 350 or 220,
            })

            if m.count > 1 then
                pcall(vim.api.nvim_buf_set_extmark, bufnr, ns_virt, m.row, 0, {
                    virt_text = {
                        {
                            string.format(' ×%d ', m.count),
                            'TelescopeGrepMatchCount',
                        },
                    },
                    virt_text_pos = 'right_align',
                    priority = 260,
                })
            end

            -- if m.is_target then
            --     local box_width =
            --         math.min(vim.api.nvim_win_get_width(winid) - 8, 80)
            --     if m.row > 0 then
            --         pcall(
            --             vim.api.nvim_buf_set_extmark,
            --             bufnr,
            --             ns_virt,
            --             m.row - 1,
            --             0,
            --             {
            --                 virt_lines = {
            --                     {
            --                         {
            --                             '╭'
            --                                 .. string.rep('─', box_width - 2)
            --                                 .. '╮',
            --                             'TelescopeGrepBox',
            --                         },
            --                     },
            --                 },
            --                 virt_lines_above = false,
            --                 priority = 290,
            --             }
            --         )
            --     end
            --     if m.row < line_count - 1 then
            --         pcall(
            --             vim.api.nvim_buf_set_extmark,
            --             bufnr,
            --             ns_virt,
            --             m.row,
            --             0,
            --             {
            --                 virt_lines = {
            --                     {
            --                         {
            --                             '╰'
            --                                 .. string.rep('─', box_width - 2)
            --                                 .. '╯',
            --                             'TelescopeGrepBox',
            --                         },
            --                     },
            --                 },
            --                 virt_lines_above = false,
            --                 priority = 290,
            --             }
            --         )
            --     end
            --     pcall(vim.api.nvim_buf_set_extmark, bufnr, ns_virt, m.row, 0, {
            --         virt_text = {
            --             { '  ', 'NONE' },
            --             { '🎯 ', 'TelescopeGrepIcon' },
            --             {
            --                 string.format(
            --                     'Match %d/%d ',
            --                     idx,
            --                     decoration_count
            --                 ),
            --                 'TelescopeGrepMatchCount',
            --             },
            --             {
            --                 string.format('(×%d) ', m.count),
            --                 'TelescopeGrepMatch',
            --             },
            --         },
            --         virt_text_pos = 'right_align',
            --         priority = 310,
            --     })
            -- end
        end

        local filename = vim.fn.fnamemodify(entry.filename, ':t')
        local filepath_display = vim.fn.fnamemodify(entry.filename, ':~:.')
        local icon = '󰈔'
        if has_devicons then
            icon = devicons.get_icon(
                filename,
                vim.fn.fnamemodify(filename, ':e'),
                { default = true }
            ) or '󰈔'
        end

        local file_stat = vim.uv.fs_stat(entry.filename)
        local file_size = 'N/A'
        if file_stat then
            if file_stat.size < 1024 then
                file_size = file_stat.size .. 'B'
            elseif file_stat.size < 1048576 then
                file_size = math.floor(file_stat.size / 1024) .. 'KB'
            else
                file_size = math.floor(file_stat.size / 1048576) .. 'MB'
            end
        end

        local hw = math.min(vim.api.nvim_win_get_width(winid) - 6, 82)
        local path_display_width =
            vim.fn.strdisplaywidth(icon .. ' ' .. filepath_display)
        local path_padding =
            string.rep(' ', math.max(0, hw - path_display_width - 2))

        pcall(vim.api.nvim_buf_set_extmark, bufnr, ns_virt, 0, 0, {
            virt_lines = {
                {
                    {
                        '╭' .. string.rep('─', hw) .. '╮',
                        'TelescopeGrepBox',
                    },
                },
                {
                    { '│ ', 'TelescopeGrepBox' },
                    { icon .. ' ', 'TelescopeGrepIcon' },
                    { filepath_display, 'TelescopeGrepPath' },
                    { path_padding, 'NONE' },
                    { ' │', 'TelescopeGrepBox' },
                },
                {
                    { '│ ', 'TelescopeGrepBox' },
                    { '📊 ', 'TelescopeGrepIcon' },
                    {
                        string.format(
                            '%d matches in %d lines',
                            total_matches,
                            decoration_count
                        ),
                        'TelescopeGrepMatchCount',
                    },
                    { '  •  ', 'TelescopeGrepBorder' },
                    { '📏 ' .. file_size, 'TelescopeGrepContext' },
                    { '  •  ', 'TelescopeGrepBorder' },
                    {
                        string.format('Line %d/%d', lnum, line_count),
                        'TelescopeGrepContext',
                    },
                    { string.rep(' ', 4), 'NONE' },
                    { ' │', 'TelescopeGrepBox' },
                },
                {
                    {
                        '╰' .. string.rep('─', hw) .. '╯',
                        'TelescopeGrepBox',
                    },
                },
                { { '', 'NONE' } },
            },
            virt_lines_above = true,
            priority = 420,
        })

        pcall(function()
            vim.api.nvim_win_set_cursor(winid, { lnum, 0 })
            vim.api.nvim_win_call(winid, function()
                vim.cmd('normal! zz')
            end)
        end)
    end

    local custom_previewer = previewers.new_buffer_previewer({
        title = 'Context',
        define_preview = function(self, entry)
            local filepath = entry.cwd .. '/' .. entry.filename

            -- local filepath = entry
            --     and (entry.filename or (entry.value and entry.value.path))
            -- if not filepath then
            --     return
            -- end

            local bufnr = self.state.bufnr
            local winid = self.state.winid
            if
                not (
                    bufnr
                    and vim.api.nvim_buf_is_valid(bufnr)
                    and winid
                    and vim.api.nvim_win_is_valid(winid)
                )
            then
                return
            end

            if preview_timer then
                preview_timer:stop()
                preview_timer:close()
                preview_timer = nil
            end

            conf.buffer_previewer_maker(
                filepath,
                bufnr,
                { bufname = self.state.bufname, winid = winid }
            )

            vim.defer_fn(function()
                vim.schedule(function()
                    apply_styling(bufnr, winid, entry, 1)
                end)
            end, 20)
        end,
        teardown = function()
            if preview_timer then
                preview_timer:stop()
                preview_timer:close()
                preview_timer = nil
            end
        end,
    })

    local finder = finders.new_job(function(prompt)
        if not prompt or prompt == '' then
            return nil
        end
        local pieces =
            vim.split(prompt, '  ', { plain = true, trimempty = true })
        local search_term = pieces[1]
        if not search_term or search_term == '' then
            return nil
        end

        current_search_term = search_term
        local args = { 'rg' }
        local is_regex = search_term:match('^regex:')

        if is_regex then
            local pattern = search_term:match('^regex:(.+)$')
            if not pattern then
                return nil
            end
            vim.list_extend(args, { '-e', pattern })
        else
            vim.list_extend(args, { '-e', search_term })
        end

        if pieces[2] and pieces[2] ~= '' then
            vim.list_extend(args, { '-g', pieces[2] })
        end

        return vim.iter({ args, base_args, additional_args })
            :flatten()
            :totable()
    end, custom_entry_maker(opts), nil, opts.cwd)

    pickers
        .new(opts, {
            prompt_title = '  Live Grep  term  glob │ regex:/pat/  *.lua',
            results_title = '  Matches',
            preview_title = '  Context',
            debounce = 16,
            finder = finder,
            previewer = custom_previewer,
            -- custom_layout = layouts.live_grep,
            layout_strategy = 'vertical',
            layout_config = {
                width = vim.o.columns - 2,
                height = vim.o.lines - 4,
            },
            sorter = conf.generic_sorter(opts),
            attach_mappings = function(prompt_bufnr, map)
                local action_state = require('telescope.actions.state')
                actions.select_default:replace(function()
                    local entry = action_state.get_selected_entry()
                    actions.close(prompt_bufnr)
                    if not entry then
                        return
                    end

                    -- prefer filename, fall back to common alternatives
                    -- local fname = entry.filename or entry.path or entry.value
                    -- if not fname then
                    --     return
                    -- end

                    local fname = entry.cwd .. '/' .. entry.filename

                    vim.cmd('edit ' .. vim.fn.fnameescape(fname))

                    -- compute safe lnum / col
                    local lnum = entry.lnum or entry.row or 1
                    local col = entry.col or entry.colnum or 1

                    -- ensure buffer is ready
                    local bufnr = vim.api.nvim_get_current_buf()
                    local line_count = vim.api.nvim_buf_line_count(bufnr)
                    lnum = math.max(1, math.min(lnum, line_count))

                    -- get the target line to clamp column to its byte length
                    local line = vim.api.nvim_buf_get_lines(
                        bufnr,
                        lnum - 1,
                        lnum,
                        true
                    )[1] or ''
                    local maxcol = #line -- byte length
                    col = math.max(0, (col - 1))
                    col = math.min(col, maxcol)

                    vim.api.nvim_win_set_cursor(0, { lnum, col })
                    vim.cmd('norm! zz')
                end)
                map('i', '<C-q>', function()
                    actions.send_to_qflist(prompt_bufnr)
                    actions.open_qflist(prompt_bufnr)
                end)
                map('i', '<M-q>', function()
                    actions.send_selected_to_qflist(prompt_bufnr)
                    actions.open_qflist(prompt_bufnr)
                end)
                map('i', '<C-v>', actions.select_vertical)
                map('i', '<C-x>', actions.select_horizontal)
                return true
            end,
            cache_picker = { num_pickers = 3, limit_entries = 500 },
        })
        :find()
end

vim.api.nvim_create_autocmd('User', {
    pattern = 'TelescopePreviewerLoaded',
    callback = function()
        vim.wo.number = true
        vim.wo.scrolloff = 3
    end,
})

--- Setup custom highlight groups for better visual distinction
--- Should be called after colorscheme is loaded
function M.setup_highlights()
    vim.api.nvim_set_hl(0, 'TelescopeMatching', {
        fg = '#ff9e64',
        bold = false,
        underline = true,
    })
    vim.api.nvim_set_hl(0, 'TelescopeResultsIdentifier', {
        fg = '#7aa2f7',
        italic = true,
    })
    vim.api.nvim_set_hl(0, 'TelescopeResultsLineNr', {
        fg = '#565f89',
    })

    vim.api.nvim_set_hl(0, 'TelescopePreviewMatch', {
        bg = '#ff9e64',
        fg = '#1a1b26',
        bold = false,
    })
end
--- Quick grep for word under cursor across workspace
--- @param opts? table<string, any>
--- @usage :lua require('plugins.telescope.pickers').grep_word_under_cursor()
function M.grep_word_under_cursor(opts)
    opts = opts or {}
    local word = vim.fn.expand('<cword>')
    opts.default_text = word
    M.grep_across_workspace(opts)
end

--- Grep with specific file type filter
--- @param file_pattern string File pattern (e.g., "*.lua", "*.ts")
--- @param opts? table<string, any>
--- @usage :lua require('plugins.telescope.pickers').grep_filetype('*.lua')
function M.grep_filetype(file_pattern, opts)
    opts = opts or {}
    opts.default_text = '  ' .. file_pattern
    M.grep_across_workspace(opts)
end

--- Grep current word in the current working directory
---@usage :lua require('plugins.telescope.custom_pickers').grep_cword_in_workspace()
function M.grep_cword_in_workspace()
    local word = vim.fn.expand('<cword>')
    local root_dir = dir_utils.get_root_dir() or vim.loop.cwd()

    -- get_live_grep_opts might return nil; ensure we have a table
    local base_opts = get_live_grep_opts({ root_dir }, {}) or {}

    -- vim.tbl_extend requires at least 3 arguments: behaviour, table1, table2
    local opts = vim.tbl_extend('force', base_opts, {
        cwd = root_dir,
        default_text = word,
    })

    builtin.live_grep(opts)
end

--- Grep visual selection in the current working directory
---@usage :lua require('plugins.telescope.custom_pickers').grep_visual_selection_in_workspace()
function M.grep_visual_selection_in_workspace()
    local visual_selection = dir_utils.get_visual_selection()
    local root_dir = dir_utils.get_root_dir()
    local base_opts = get_live_grep_opts({ root_dir }, {}) or {}
    builtin.live_grep(
        vim.tbl_extend(
            'force',
            base_opts,
            get_live_grep_opts({ root_dir }, {
                cwd = root_dir,
                default_text = visual_selection,
            })
        )
    )
end

--- Grep in current buffer
---@usage :lua require('plugins.telescope.custom_pickers').grep_in_current_buffer()
function M.grep_in_current_buffer()
    local root_dir = dir_utils.get_root_dir()
    builtin.current_buffer_fuzzy_find(vim.tbl_extend('force', {
        cwd = root_dir,
        hidden = false,
        follow = true,
        search_dirs = { root_dir },
    }, get_vertical_layout()))
end

--- Grep inside current project
---@usage :lua require('plugins.telescope.custom_pickers').grep_inside_project()
function M.grep_inside_project()
    local root_dir = dir_utils.get_root_dir()
    builtin.live_grep(get_live_grep_opts({ root_dir }, {
        prompt_title = 'Search Inside Project',
        cwd = root_dir,
    }))
end

--- Grep functions inside the current project
---@usage :lua require('plugins.telescope.custom_pickers').grep_functions_inside_project()
function M.grep_functions_inside_project()
    local root_dir = M.find_project_root()
    builtin.live_grep(get_live_grep_opts({ root_dir }, {
        prompt_title = 'Find Function in Project',
    }))
end

--- Grep TODOs inside the current project
---@usage :lua require('plugins.telescope.custom_pickers').grep_todos_inside_project()
function M.grep_todos_inside_project()
    local root_dir = M.find_project_root()
    builtin.live_grep(get_live_grep_opts({ root_dir }, {
        title = 'TODOs',
        prompt_prefix = 'TODO: ',
        search = 'TODO',
        cwd = root_dir,
    }))
end

-- ============================================================================
-- Help Functions
-- ============================================================================

--- Grep in help_tags
---@usage :lua require('plugins.telescope.custom_pickers').grep_in_help_tags()
function M.grep_in_help_tags()
    builtin.help_tags(vim.tbl_extend('force', {
        cwd = vim.fn.stdpath('data') .. '/doc',
        hidden = false,
        follow = true,
        search_dirs = { vim.fn.stdpath('data') .. '/doc' },
    }, get_help_layout()))
end

--- Grep current word in help_tags
---@usage :lua require('plugins.telescope.custom_pickers').grep_cword_in_help_tags()
function M.grep_cword_in_help_tags()
    local word = vim.fn.expand('<cword>')
    builtin.help_tags(vim.tbl_extend('force', {
        hidden = false,
        search_dirs = { vim.fn.stdpath('data') .. '/doc' },
        default_text = word,
    }, get_help_layout()))
end

--- Grep visual selection in help_tags
---@usage :lua require('plugins.telescope.custom_pickers').grep_visual_selection_in_help_tags()
function M.grep_visual_selection_in_help_tags()
    local visual_selection = dir_utils.get_visual_selection()
    builtin.help_tags(vim.tbl_extend('force', {
        grep_open_files = true,
        default_text = visual_selection,
    }, get_help_layout()))
end

-- ============================================================================
-- Knowledge Base Functions
-- ============================================================================

--- Grep notes in knowledge base
---@usage :lua require('plugins.telescope.custom_pickers').grep_notes()
function M.grep_notes()
    builtin.live_grep(get_live_grep_opts({ '~/Knowledge' }, {
        title = 'Notes',
        search_dirs = { '~/Knowledge' },
    }))
end

--- Grep notes without tags in knowledge base
---@usage :lua require('plugins.telescope.custom_pickers').grep_notes_without_tags()
function M.grep_notes_without_tags()
    builtin.live_grep(get_live_grep_opts({ '~/Knowledge' }, {
        prompt_title = 'Notes (excluding tags)',
        search_dirs = { '~/Knowledge' },
        glob_pattern = '!**/tags/**',
    }))
end

--- Grep inside knowledge base
---@usage :lua require('plugins.telescope.custom_pickers').grep_inside_knowledge()
function M.grep_inside_knowledge()
    builtin.live_grep(get_live_grep_opts({ '~/Knowledge' }, {
        prompt_title = 'Searching Inside Knowledge Base',
        search_dirs = { '~/Knowledge' },
    }))
end

--- Grep TODOs inside knowledge base
---@usage :lua require('plugins.telescope.custom_pickers').grep_todos_inside_knowledge()
function M.grep_todos_inside_knowledge()
    builtin.live_grep(get_live_grep_opts({ '~/Knowledge' }, {
        title = 'TODOs',
        prompt_prefix = 'TODO: ',
        search = '- [ ]',
        search_dirs = { '~/Knowledge' },
    }))
end

--- Find files in knowledge base
---@usage :lua require('plugins.telescope.custom_pickers').find_files_in_knowledge_base()
function M.find_files_in_knowledge_base()
    builtin.live_grep(get_live_grep_opts({ '~/Knowledge' }, {
        prompt_title = 'Find Files in Knowledge Base',
        cwd = '~/Knowledge',
    }))
end

--- List inlinks to the current file in the knowledge base
---@usage :lua require('plugins.telescope.custom_pickers').list_inlinks()
function M.list_inlinks()
    local current_file_name = vim.fn.expand('%:t:r')
    local current_file_extension = vim.fn.expand('%:e')

    if current_file_extension ~= 'md' then
        vim.notify('Not a markdown file', vim.log.levels.WARN)
        return
    end

    local knowledge_base = '~/Knowledge'
    local search_pattern = current_file_name .. '%]%]'

    local results = vim.fn.systemlist(
        'rg --files-with-matches '
            .. vim.fn.shellescape(search_pattern)
            .. ' '
            .. knowledge_base
    )

    if #results == 0 then
        vim.notify('No inlinks found', vim.log.levels.INFO)
        return
    end

    builtin.find_files(vim.tbl_extend('force', {
        prompt_title = 'Inlinks',
        cwd = knowledge_base,
        search_dirs = { knowledge_base },
        find_command = {
            'rg',
            '--files-with-matches',
            search_pattern,
            knowledge_base,
        },
    }, get_vertical_layout()))
end

-- ============================================================================
-- LSP & Navigation Functions
-- ============================================================================

--- Go to definition
---@usage :lua require('plugins.telescope.custom_pickers').goto_definition()
function M.goto_definition()
    builtin.lsp_definitions({
        prompt_title = 'Go to Definition',
    })
end

--- Go to definition from visual selection
---@usage :lua require('plugins.telescope.custom_pickers').goto_definition_from_visual_selection()
function M.goto_definition_from_visual_selection()
    local visual_selection = dir_utils.get_visual_selection()
    builtin.lsp_definitions({
        prompt_title = 'Go to Definition',
        default_text = visual_selection,
    })
end

--- Go to definition with vertical split
---@usage :lua require('plugins.telescope.custom_pickers').goto_definition_with_vertical_split()
function M.goto_definition_with_vertical_split()
    vim.cmd('vsplit')
    M.goto_definition()
end

--- Go to definition with horizontal split
---@usage :lua require('plugins.telescope.custom_pickers').goto_definition_with_horizontal_split()
function M.goto_definition_with_horizontal_split()
    vim.cmd('split')
    M.goto_definition()
end

--- Document symbols for selected file
---@param prompt_bufnr number
local function document_symbols_for_selected(prompt_bufnr)
    local entry = actions_state.get_selected_entry()

    if entry == nil then
        vim.notify('No file selected', vim.log.levels.WARN)
        return
    end

    actions.close(prompt_bufnr)

    vim.schedule(function()
        local bufnr = vim.fn.bufadd(entry.path)
        vim.fn.bufload(bufnr)

        local params =
            { textDocument = vim.lsp.util.make_text_document_params(bufnr) }

        vim.lsp.buf_request(
            bufnr,
            'textDocument/documentSymbol',
            params,
            function(err, result, _, _)
                if err then
                    vim.notify(
                        'Error getting document symbols: ' .. vim.inspect(err),
                        vim.log.levels.ERROR
                    )
                    return
                end

                if not result or vim.tbl_isempty(result) then
                    vim.notify('No symbols found', vim.log.levels.INFO)
                    return
                end

                local function flatten_symbols(symbols, parent_name)
                    local flattened = {}
                    for _, symbol in ipairs(symbols) do
                        local name = symbol.name
                        if parent_name then
                            name = parent_name .. '.' .. name
                        end
                        table.insert(flattened, {
                            name = name,
                            kind = symbol.kind,
                            range = symbol.range,
                            selectionRange = symbol.selectionRange,
                        })
                        if symbol.children then
                            local children =
                                flatten_symbols(symbol.children, name)
                            vim.list_extend(flattened, children)
                        end
                    end
                    return flattened
                end

                local flat_symbols = flatten_symbols(result)

                vim.cmd([[highlight TelescopeSymbolKind guifg=#61AFEF]])

                pickers
                    .new({}, {
                        prompt_title = 'Document Symbols: '
                            .. vim.fn.fnamemodify(entry.path, ':t'),
                        finder = finders.new_table({
                            results = flat_symbols,
                            entry_maker = function(symbol)
                                local kind = vim.lsp.protocol.SymbolKind[symbol.kind]
                                    or 'Other'
                                return {
                                    value = symbol,
                                    display = function(display_entry)
                                        local display_text = string.format(
                                            '%-50s %s',
                                            display_entry.value.name,
                                            kind
                                        )
                                        return display_text,
                                            {
                                                {
                                                    {
                                                        #display_entry.value.name
                                                            + 1,
                                                        #display_text,
                                                    },
                                                    'TelescopeSymbolKind',
                                                },
                                            }
                                    end,
                                    ordinal = symbol.name,
                                    filename = entry.path,
                                    lnum = symbol.selectionRange.start.line + 1,
                                    col = symbol.selectionRange.start.character
                                        + 1,
                                }
                            end,
                        }),
                        sorter = conf.generic_sorter({}),
                        previewer = conf.qflist_previewer({}),
                        attach_mappings = function(_, map)
                            map('i', '<CR>', function(inner_prompt_bufnr)
                                local selection =
                                    actions_state.get_selected_entry()
                                actions.close(inner_prompt_bufnr)
                                vim.cmd(
                                    'edit '
                                        .. vim.fn.fnameescape(
                                            selection.filename
                                        )
                                )
                                local lnum = tonumber(selection.lnum) or 1
                                local col = tonumber(selection.col) or 1
                                vim.api.nvim_win_set_cursor(
                                    0,
                                    { lnum, col - 1 }
                                )
                            end)

                            return true
                        end,
                    })
                    :find()
            end
        )
    end)
end

-- ============================================================================
-- File Browser Functions
-- ============================================================================

--- Browse files from home
---@usage :lua require('plugins.telescope.custom_pickers').browse_files()
function M.browse_files()
    local telescope = package.loaded['telescope']
    if not telescope or not telescope.extensions.file_browser then
        vim.notify('file_browser extension not loaded', vim.log.levels.ERROR)
        return
    end

    telescope.extensions.file_browser.file_browser({
        title = 'Browse Files',
        path_display = { 'smart' },
        cwd = '~',
        layout_strategy = 'horizontal',
        layout_config = { preview_width = 0.65, width = 0.75 },
        hidden = true,
        dir_icon = '▪',
        dir_icon_hl = 'TelescopeFileBrowserDirIcon',
        grouped = true,
    })
end

--- Browse files in current project
---@usage :lua require('plugins.telescope.custom_pickers').browse_files_in_project()
function M.browse_files_in_project()
    local root_dir = M.find_project_root()
    if not root_dir then
        vim.notify('No project root found', vim.log.levels.WARN)
        return
    end

    local telescope = package.loaded['telescope']
    if not telescope or not telescope.extensions.file_browser then
        vim.notify('file_browser extension not loaded', vim.log.levels.ERROR)
        return
    end

    telescope.extensions.file_browser.file_browser({
        title = 'Browse Files',
        path_display = { 'smart' },
        cwd = root_dir,
        layout_strategy = 'horizontal',
        layout_config = { preview_width = 0.65, width = 0.75 },
        hidden = true,
        dir_icon = '▪',
        dir_icon_hl = 'TelescopeFileBrowserDirIcon',
        grouped = true,
    })
end

--- Browse Eagle assets
---@usage :lua require('plugins.telescope.custom_pickers').browse_eagle_assets()
function M.browse_eagle_assets()
    local root_dir = '~/Macbook Air.library/'
    local telescope = package.loaded['telescope']

    if not telescope or not telescope.extensions.media_files then
        vim.notify('media_files extension not loaded', vim.log.levels.ERROR)
        return
    end

    telescope.extensions.media_files.media_files({
        cwd = root_dir,
    })
end

-- ============================================================================
-- Buffer & Mapping Functions
-- ============================================================================

--- List buffers
---@usage :lua require('plugins.telescope.custom_pickers').list_buffers()
function M.list_buffers()
    builtin.buffers({
        show_all_buffers = true,
        sort_lastused = true,
        previewer = false,
        layout_strategy = 'horizontal',
        layout_config = {
            width = 0.8,
            height = 0.8,
            prompt_position = 'top',
            preview_cutoff = 120,
        },
    })
end

--- Browse keymaps
---@usage :lua require('plugins.telescope.custom_pickers').browse_mappings()
function M.browse_mappings()
    builtin.keymaps({
        layout_strategy = 'horizontal',
        prompt_prefix = 'Mappings: ',
        layout_config = {
            width = 0.8,
            height = 0.8,
            prompt_position = 'top',
            preview_cutoff = 120,
        },
    })
end

--- Browse keymaps with leader key
---@usage :lua require('plugins.telescope.custom_pickers').browse_mappings_with_leader()
function M.browse_mappings_with_leader()
    builtin.keymaps({
        default_text = '<Space>',
        prompt_prefix = 'Mappings: ',
        layout_strategy = 'horizontal',
        layout_config = {
            width = 0.9,
            height = 0.9,
            prompt_position = 'top',
            preview_cutoff = 120,
        },
        search = '<Space>',
    })
end

--- Browse keymaps starting with specific character
---@param char string
---@usage :lua require('plugins.telescope.custom_pickers').browse_mappings_starts_with_char('g')
function M.browse_mappings_starts_with_char(char)
    builtin.keymaps({
        default_text = char,
        prompt_prefix = 'Mappings: ',
        layout_strategy = 'horizontal',
        layout_config = {
            width = 0.9,
            height = 0.9,
            prompt_position = 'top',
            preview_cutoff = 120,
        },
        search = char,
        lhs_filter = false,
    })
end

--- Alias for backwards compatibility
---@param char string
function M.browse_mappings_with_char(char)
    M.browse_mappings_starts_with_char(char)
end

-- ============================================================================
-- Repository Functions
-- ============================================================================

--- Fetch and list repositories
---@usage :lua require('plugins.telescope.custom_pickers').fetch_repos()
function M.fetch_repos()
    local telescope = package.loaded['telescope']
    if not telescope or not telescope.extensions.repo then
        vim.notify('repo extension not loaded', vim.log.levels.ERROR)
        return
    end

    local function enter(prompt_bufnr)
        local entry = actions_state.get_selected_entry()
        actions.close(prompt_bufnr)
        vim.api.nvim_set_current_dir(entry.value)
        vim.cmd('edit .')
    end

    telescope.extensions.repo.list({
        search_dirs = { '~' },
        fd_opts = {
            '--hidden',
            '--absolute-path',
            '--max-depth',
            '2',
            '--type',
            'd',
        },
        layout_config = {
            width = 0.9,
            height = 0.9,
            prompt_position = 'top',
            preview_cutoff = 120,
            preview_width = 0.65,
        },
        attach_mappings = function()
            actions.select_default:replace(enter)
            return true
        end,
    })
end

--- Browse projects (alias for fetch_repos)
---@usage :lua require('plugins.telescope.custom_pickers').browse_projects()
function M.browse_projects()
    M.fetch_repos()
end

-- ============================================================================
-- Plugin Search Functions
-- ============================================================================

--- Search across nvim plugins data directory
---@usage :lua require('plugins.telescope.custom_pickers').nvim_plugins()
function M.nvim_plugins()
    local XDG_DATA_HOME = vim.env.XDG_DATA_HOME
        or (vim.env.HOME .. '/.local/share')
    local nvim_data = XDG_DATA_HOME .. '/nvim'

    builtin.live_grep(get_live_grep_opts({ nvim_data }, {
        prompt_title = 'Searching Inside nvim data',
        search_dirs = { nvim_data },
    }))
end

-- ============================================================================
-- Keymap Setup
-- ============================================================================

local function setup_keymaps()
    local keymap_opts = { silent = true, noremap = true }

    -- Project navigation
    vim.keymap.set(
        'n',
        '<leader>P',
        M.browse_projects,
        vim.tbl_extend('force', keymap_opts, { desc = 'browse projects' })
    )
    vim.keymap.set(
        'n',
        '<leader>p',
        M.choose_picker,
        vim.tbl_extend('force', keymap_opts, { desc = 'telescope pickers' })
    )
    vim.keymap.set(
        'n',
        '<leader>o',
        M.open_file_in_workspace,
        vim.tbl_extend(
            'force',
            keymap_opts,
            { desc = 'open file from project' }
        )
    )
    vim.keymap.set(
        'n',
        '<leader>O',
        M.open_file_from_home,
        vim.tbl_extend('force', keymap_opts, { desc = 'open file from home' })
    )

    -- Grep commands
    vim.keymap.set(
        'n',
        '<leader>gw',
        M.grep_across_workspace,
        vim.tbl_extend('force', keymap_opts, { desc = 'grep across workspace' })
    )
    vim.keymap.set(
        'n',
        '<leader>gh',
        M.grep_cword_in_help_tags,
        vim.tbl_extend('force', keymap_opts, { desc = 'grep cword in help' })
    )
    vim.keymap.set(
        'v',
        '<leader>gh',
        M.grep_visual_selection_in_help_tags,
        vim.tbl_extend(
            'force',
            keymap_opts,
            { desc = 'grep visual selection in help' }
        )
    )
    vim.keymap.set(
        'n',
        '<leader>*',
        M.grep_cword_in_workspace,
        vim.tbl_extend(
            'force',
            keymap_opts,
            { desc = 'grep cword in workspace' }
        )
    )
    vim.keymap.set(
        'v',
        '<leader>*',
        M.grep_visual_selection_in_workspace,
        vim.tbl_extend(
            'force',
            keymap_opts,
            { desc = 'grep visual selection in workspace' }
        )
    )
    vim.keymap.set(
        'n',
        '<leader>/',
        M.grep_in_current_buffer,
        vim.tbl_extend(
            'force',
            keymap_opts,
            { desc = 'grep in current buffer' }
        )
    )

    -- Knowledge base
    vim.keymap.set(
        'n',
        '<leader>k',
        M.grep_notes,
        vim.tbl_extend(
            'force',
            keymap_opts,
            { desc = 'grep in Knowledge folder' }
        )
    )
    vim.keymap.set(
        'n',
        '<leader>in',
        M.grep_notes_without_tags,
        vim.tbl_extend(
            'force',
            keymap_opts,
            { desc = 'grep in Knowledge folder, ignoring tags' }
        )
    )
    vim.keymap.set(
        'n',
        '<leader>ik',
        M.grep_inside_knowledge,
        vim.tbl_extend(
            'force',
            keymap_opts,
            { desc = 'grep in Knowledge folder, ignoring hidden files' }
        )
    )
    vim.keymap.set(
        'n',
        '<leader>ikt',
        M.grep_todos_inside_knowledge,
        vim.tbl_extend(
            'force',
            keymap_opts,
            { desc = 'grep TODOs in Knowledge folder' }
        )
    )

    -- Project grep
    vim.keymap.set(
        'n',
        '<leader>ip',
        M.grep_inside_project,
        vim.tbl_extend(
            'force',
            keymap_opts,
            { desc = 'Grep inside current project' }
        )
    )
    vim.keymap.set(
        'n',
        '<leader>ipf',
        M.grep_functions_inside_project,
        vim.tbl_extend(
            'force',
            keymap_opts,
            { desc = 'grep functions in project' }
        )
    )
    vim.keymap.set(
        'n',
        '<leader>iptd',
        M.grep_todos_inside_project,
        vim.tbl_extend('force', keymap_opts, { desc = 'grep TODOs in project' })
    )

    -- LSP navigation
    vim.keymap.set(
        'n',
        'gd',
        M.goto_definition,
        vim.tbl_extend('force', keymap_opts, { desc = 'go to definition' })
    )
    vim.keymap.set(
        'v',
        'gdv',
        M.goto_definition_from_visual_selection,
        vim.tbl_extend(
            'force',
            keymap_opts,
            { desc = 'go to definition from visual selection' }
        )
    )
    vim.keymap.set(
        'n',
        '<leader>gdv',
        M.goto_definition_with_vertical_split,
        vim.tbl_extend(
            'force',
            keymap_opts,
            { desc = 'go to definition with vertical split' }
        )
    )
    vim.keymap.set(
        'n',
        '<leader>gds',
        M.goto_definition_with_horizontal_split,
        vim.tbl_extend(
            'force',
            keymap_opts,
            { desc = 'go to definition with horizontal split' }
        )
    )
    vim.keymap.set(
        'n',
        '<leader>ds',
        document_symbols_for_selected,
        vim.tbl_extend(
            'force',
            keymap_opts,
            { desc = 'Document symbols for selected file' }
        )
    )

    -- Buffers and mappings
    vim.keymap.set(
        'n',
        '<leader>bb',
        M.list_buffers,
        vim.tbl_extend('force', keymap_opts, { desc = 'list buffers' })
    )
    vim.keymap.set(
        'n',
        '<leader>bm',
        M.browse_mappings_with_leader,
        vim.tbl_extend(
            'force',
            keymap_opts,
            { desc = 'Browse mappings with <leader>' }
        )
    )

    -- File browsers
    vim.keymap.set(
        'n',
        '<leader>E',
        M.browse_files,
        vim.tbl_extend(
            'force',
            keymap_opts,
            { desc = 'Blazing fast file browser in whole home' }
        )
    )

    -- Plugins
    vim.keymap.set(
        'n',
        '<leader>np',
        M.nvim_plugins,
        vim.tbl_extend('force', keymap_opts, { desc = 'grep in nvim plugins' })
    )

    -- Git
    vim.keymap.set(
        'n',
        '<leader>gs',
        builtin.git_status,
        vim.tbl_extend('force', keymap_opts, { desc = 'Git status' })
    )
    vim.keymap.set(
        'n',
        '<leader>gb',
        builtin.git_branches,
        vim.tbl_extend('force', keymap_opts, { desc = 'Git branches' })
    )
end

--- Setup character-based keymap navigation
local function setup_char_mappings()
    local keymaps = vim.api.nvim_get_keymap('n')
    local char_set = {}

    -- Build set of chars that have mappings
    for _, key in ipairs(keymaps) do
        local first_char = key.lhs:sub(1, 1)
        if first_char ~= '' then
            char_set[first_char] = true
        end
    end

    -- Only create mappings for chars that exist
    for char in pairs(char_set) do
        vim.keymap.set('n', '<leader>bm' .. char, function()
            M.browse_mappings_starts_with_char(char)
        end, {
            silent = true,
            noremap = true,
            desc = 'Browse mappings with ' .. char,
        })
    end
end

-- ============================================================================
-- User Commands
-- ============================================================================

local function setup_commands()
    vim.api.nvim_create_user_command(
        'GrepNotesWithoutTags',
        M.grep_notes_without_tags,
        {
            nargs = '*',
            desc = 'Grep notes without tags',
        }
    )

    vim.api.nvim_create_user_command('GrepNotes', M.grep_notes, {
        nargs = '*',
        desc = 'Grep notes in knowledge base',
    })

    vim.api.nvim_create_user_command(
        'TelescopeBrowseFilesInProject',
        M.browse_files_in_project,
        {
            nargs = '*',
            desc = 'Browse files in current project',
        }
    )

    vim.api.nvim_create_user_command('FetchListOfRepos', M.fetch_repos, {
        nargs = 0,
        desc = 'Fetch and list repositories',
    })

    vim.api.nvim_create_user_command('NvimPlugins', M.nvim_plugins, {
        nargs = '*',
        desc = 'Search in nvim plugins',
    })

    vim.api.nvim_create_user_command('GotoDefinition', M.goto_definition, {
        nargs = '*',
        desc = 'Go to definition via Telescope',
    })
end

-- Initialize keymaps and commands
setup_keymaps()
setup_char_mappings()
setup_commands()

-- Setup highlights after colorscheme loads
vim.schedule(function()
    -- Wait for colorscheme to be fully loaded
    vim.defer_fn(function()
        M.setup_highlights()
    end, 100)
end)

return M
