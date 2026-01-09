--[[
    CONFIG.AUTOCMDS
    Architecture: Event-Driven Architecture with Native API Optimization
    Performance:  O(1) Filetype detection, JIT-compiled Lua callbacks
--]]

local api = vim.api
local fn = vim.fn
local cmd = vim.cmd

-- 1. GROUP MANAGEMENT
---@param name string
---@return number id
local function augroup(name)
    return api.nvim_create_augroup('cfg_' .. name, { clear = true })
end

-- ============================================================================
--  2. EDITOR BEHAVIOR (Formatting, Yanking, Cursor)
-- ============================================================================

local grp_behavior = augroup('EditorBehavior')

-- Smart Cursor Restoration
api.nvim_create_autocmd('BufReadPost', {
    group = grp_behavior,
    callback = function(args)
        local mark = api.nvim_buf_get_mark(args.buf, '"')
        local line_count = api.nvim_buf_line_count(args.buf)
        if mark[1] > 0 and mark[1] <= line_count then
            pcall(api.nvim_win_set_cursor, 0, mark)
            cmd('norm! zz') -- Center screen
        end
    end,
})

-- Optimized Trailing Whitespace Removal
api.nvim_create_autocmd('BufWritePre', {
    group = grp_behavior,
    pattern = '*',
    callback = function()
        -- Skip binary files or diffs
        if vim.bo.binary or vim.bo.filetype == 'diff' then
            return
        end

        local view = fn.winsaveview()
        -- Simplified command to avoid E148 issues
        -- %s/\s\+$//e : Remove trailing whitespace, 'e' flag suppresses error if none found
        cmd([[silent! %s/\s\+$//e]])
        fn.winrestview(view)
    end,
})

-- Visual Yank Highlight with Fancy Animation
api.nvim_create_autocmd('TextYankPost', {
    group = grp_behavior,
    pattern = '*',
    callback = function()
        local ns_id = api.nvim_create_namespace('yank_highlight')
        local win_id = api.nvim_get_current_win()
        local buf_id = api.nvim_get_current_buf()
        local cursor = api.nvim_win_get_cursor(win_id)
        local row, col = cursor[1] - 1, cursor[2]

        vim.highlight.on_yank({ higroup = 'IncSearch', timeout = 40 })

        local timer = vim.loop.new_timer()
        local step = 0
        local max_steps = 8
        local delay = 50

        local function animate_highlight()
            if step > max_steps then
                api.nvim_buf_clear_namespace(buf_id, ns_id, row, row + 1)
                timer:stop()
                timer:close()
                return
            end

            local hl_group = step % 2 == 0 and 'IncSearch' or 'Search'
            api.nvim_buf_add_highlight(
                buf_id,
                ns_id,
                hl_group,
                row,
                col,
                col + 1
            )

            step = step + 1
        end

        timer:start(0, delay, vim.schedule_wrap(animate_highlight))
    end,
})

-- ============================================================================
--  3. FILETYPE DETECTION (Native C-API)
-- ============================================================================

vim.filetype.add({
    extension = {
        zshrc = 'zsh',
        aliases = 'zsh',
        exports = 'zsh',
        functions = 'zsh',
        secrets = 'zsh',
        ['zsh-theme'] = 'zsh',
        psjs = 'javascript',
        applescript = 'applescript',
        scpt = 'applescript',
        scptd = 'applescript',
    },
    pattern = {
        ['.*%.env.*'] = 'sh',
        ['.*rc$'] = 'zsh',
        ['.*%.js$'] = 'javascript',
    },
})

local grp_ft = augroup('FiletypeSettings')

api.nvim_create_autocmd('FileType', {
    group = grp_ft,
    pattern = 'applescript',
    callback = function()
        vim.opt_local.tabstop = 4
        vim.opt_local.shiftwidth = 4
        vim.opt_local.expandtab = true
    end,
})

-- ============================================================================
--  4. UI & VISUALS (Dimming)
-- ============================================================================

local grp_ui = augroup('Interface')

-- Setup the "Dimmed" look
cmd('highlight default link DimInactiveWindow Comment')

api.nvim_create_autocmd('WinEnter', {
    group = grp_ui,
    callback = function()
        vim.opt_local.winhighlight = ''
    end,
})

api.nvim_create_autocmd('WinLeave', {
    group = grp_ui,
    callback = function()
        -- Guard against invalid windows or closing windows
        local ok, config = pcall(api.nvim_win_get_config, 0)

        -- 1. pcall failed (window closing)
        -- 2. config.relative ~= '' (it's a floating window)
        -- 3. buftype set (it's a special window like NvimTree or Telescope)
        if not ok or config.relative ~= '' or vim.bo.buftype ~= '' then
            return
        end

        vim.opt_local.winhighlight =
            'Normal:DimInactiveWindow,NormalNC:DimInactiveWindow'
    end,
})

vim.api.nvim_create_user_command('CodeCompanionGlow', function()
    if vim.bo.filetype == 'codecompanion' then
        local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
        local content = table.concat(lines, '\n')

        -- Write to temp file and open with glow
        local tmpfile = vim.fn.tempname() .. '.md'
        vim.fn.writefile(lines, tmpfile)
        vim.cmd('Glow ' .. tmpfile)
    else
        vim.notify('Not in a codecompanion buffer', vim.log.levels.WARN)
    end
end, { desc = 'Preview CodeCompanion chat in Glow' })

-- -- ===== AUTO-RELOAD FILES (Obsidian-friendly) =====
--
-- -- Enable auto-read globally
-- vim.opt.autoread = true
--
-- -- Check for file changes more frequently
-- vim.opt.updatetime = 1000
--
-- -- Auto-reload on various events
-- vim.api.nvim_create_autocmd({
--     'FocusGained',
--     'BufEnter',
--     'CursorHold',
--     'CursorHoldI',
-- }, {
--     pattern = '*',
--     callback = function()
--         if vim.fn.mode() ~= 'c' then
--             vim.cmd('silent! checktime')
--         end
--     end,
-- })
--
-- -- For markdown files (Obsidian), be extra aggressive
-- vim.api.nvim_create_autocmd('BufEnter', {
--     pattern = '*.md',
--     callback = function()
--         vim.opt_local.autoread = true
--         vim.opt_local.swapfile = false
--         vim.cmd('silent! checktime')
--     end,
-- })
--
-- -- Auto-reload without asking when file changes
-- vim.api.nvim_create_autocmd('FileChangedShell', {
--     pattern = '*',
--     callback = function()
--         if vim.fn.mode() ~= 'c' then
--             vim.cmd('echohl WarningMsg')
--             vim.cmd('echo "File changed, reloading..."')
--             vim.cmd('echohl None')
--             vim.cmd('edit!')
--         end
--     end,
-- })
--
-- -- Notify after reload
-- vim.api.nvim_create_autocmd('FileChangedShellPost', {
--     pattern = '*',
--     callback = function()
--         vim.notify('📝 File reloaded', vim.log.levels.INFO)
--     end,
-- })
