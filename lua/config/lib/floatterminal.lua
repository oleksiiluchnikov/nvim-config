--- Floating terminal utilities.
--- LSP-friendly module with explicit exports.

local M = {}

---@class FloatTermStateItem
---@field buf integer
---@field win integer
---@field job_id integer|nil

---@class FloatTermState
---@field floating FloatTermStateItem
---@field sidebar FloatTermStateItem
---@field cwd string|nil
---@field tabpage integer|nil
---@field sidebar_tabpage integer|nil

---@type FloatTermState
local state = {
    floating = {
        buf = -1,
        win = -1,
        job_id = nil,
    },
    sidebar = {
        buf = -1,
        win = -1,
        job_id = nil,
    },
    cwd = nil,
    tabpage = nil,
    sidebar_tabpage = nil,
}

----------------------------------------------------------------------
-- Helpers
----------------------------------------------------------------------

local function is_valid_win(win)
    return type(win) == 'number' and win > 0 and vim.api.nvim_win_is_valid(win)
end

local function is_valid_buf(buf)
    return type(buf) == 'number' and buf > 0 and vim.api.nvim_buf_is_valid(buf)
end

local function get_editor_size()
    return vim.o.columns, vim.o.lines
end

local function has_active_job(bufnr)
    if not is_valid_buf(bufnr) then
        return false
    end

    local job_id = vim.b[bufnr].terminal_job_id
    if not job_id then
        return false
    end

    local ok, pid = pcall(vim.fn.jobpid, job_id)
    if not ok or pid == 0 then
        return false
    end

    -- macOS: use ps to check for child processes
    local handle = io.popen('pgrep -P ' .. pid .. ' 2>/dev/null')
    if handle then
        local result = handle:read('*all')
        handle:close()
        return result and result:match('%S') ~= nil
    end

    return false
end

--- Create (or reuse) a centered floating window.
---@param opts? { width?: integer, height?: integer, buf?: integer }
---@return FloatTermStateItem
local function create_floating_window(opts)
    opts = opts or {}
    local columns, lines = get_editor_size()

    local width = opts.width or math.floor(columns * 0.7)
    local height = opts.height or math.floor(lines * 0.9)

    width = math.max(20, math.min(width, columns - 2))
    height = math.max(5, math.min(height, lines - 2))

    local col = math.floor((columns - width) / 2)
    local row = math.floor((lines - height) / 2)

    local buf = is_valid_buf(opts.buf) and opts.buf
        or vim.api.nvim_create_buf(false, true)

    local win_config = {
        relative = 'editor',
        width = width,
        height = height,
        col = col,
        row = row,
        style = 'minimal',
        border = 'rounded',
    }

    local win = vim.api.nvim_open_win(buf, true, win_config)
    vim.api.nvim_win_set_option(
        win,
        'winhighlight',
        'Normal:Normal,FloatBorder:FloatBorder'
    )
    vim.wo[win].winfixbuf = true
    return { buf = buf, win = win, job_id = opts.job_id }
end

--- Create (or reuse) a right-side vertical-split window, 80 cols wide.
---@param opts? { buf?: integer, job_id?: integer|nil }
---@return FloatTermStateItem
local function create_sidebar_window(opts)
    opts = opts or {}
    local buf = is_valid_buf(opts.buf) and opts.buf
        or vim.api.nvim_create_buf(false, true)

    -- Open a full-height split on the far right
    vim.cmd('botright vsplit')
    local win = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_buf(win, buf)
    vim.api.nvim_win_set_width(win, 80)

    -- Lock width and buffer so resizing other splits won't affect it
    vim.wo[win].winfixwidth = true
    vim.wo[win].winfixbuf = true

    -- Clean up UI chrome — it's a terminal, not a code buffer
    vim.wo[win].number = false
    vim.wo[win].relativenumber = false
    vim.wo[win].signcolumn = 'no'
    vim.wo[win].foldcolumn = '0'

    return { buf = buf, win = win, job_id = opts.job_id }
end

----------------------------------------------------------------------
-- Terminal keymaps & UX
----------------------------------------------------------------------

---@param bufnr integer
local function set_terminal_keymaps(bufnr)
    local opts = { buffer = bufnr, noremap = true }

    -- Exit terminal mode
    vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', opts)

    -- Quick hide/toggle (hides whichever terminal type this buffer belongs to)
    vim.keymap.set('t', '<M-d>', function()
        vim.api.nvim_feedkeys(
            vim.api.nvim_replace_termcodes('<C-\\><C-n>', true, false, true),
            'n',
            false
        )
        local m = require('config.lib.floatterminal')
        if state.sidebar.buf == bufnr then
            m.hide_sidebar()
        else
            m.hide()
        end
    end, opts)

    -- CRITICAL: Ensure Tab and completion keys pass through to shell.
    -- These override any global mappings from completion plugins (blink.cmp,
    -- ai.lua, etc.) that would otherwise intercept these in terminal buffers.
    vim.keymap.set('t', '<Tab>', '<Tab>', opts)
    vim.keymap.set('t', '<S-Tab>', '<S-Tab>', opts)
    vim.keymap.set('t', '<C-y>', '<C-y>', opts)
    vim.keymap.set('t', '<C-e>', '<C-e>', opts)
    vim.keymap.set('t', '<C-n>', '<C-n>', opts)
    vim.keymap.set('t', '<C-p>', '<C-p>', opts)
    vim.keymap.set('t', '<CR>', '<CR>', opts)
    -- Pass through keys stolen by ai.lua global 't'-mode mappings
    vim.keymap.set('t', '<C-j>', '<C-j>', opts)
    vim.keymap.set('t', '<C-l>', '<C-l>', opts)
    -- Command palette (optional, can remove if not needed)
    vim.keymap.set('t', '<M-p>', function()
        vim.cmd([[stopinsert]])
        local builtins = {
            'git status',
            'git diff',
            'ls -la',
            'rg ',
            'npm test',
            'make test',
        }
        vim.ui.select(
            builtins,
            { prompt = 'Run in floatterminal:' },
            function(choice)
                if not choice then
                    vim.cmd('startinsert')
                    return
                end
                local chan = vim.b[bufnr].terminal_job_id
                if chan then
                    vim.fn.chansend(chan, choice .. '\n')
                    vim.cmd('startinsert')
                else
                    vim.notify('No terminal job attached', vim.log.levels.WARN)
                end
            end
        )
    end, opts)
end

----------------------------------------------------------------------
-- Shell / cwd innovation
----------------------------------------------------------------------

---@return string[]
local function get_shell_cmd()
    local cwd = vim.fn.getcwd()
    local project_shell = cwd .. '/.nvim-shell'

    if vim.fn.executable(project_shell) == 1 then
        return { project_shell }
    end

    local shell = vim.o.shell or os.getenv('SHELL') or '/bin/sh'
    return { shell }
end

--- Ensure terminal buffer exists (per tabpage) and is configured.
---@return FloatTermStateItem
local function ensure_terminal()
    local current_tab = vim.api.nvim_get_current_tabpage()
    if state.tabpage ~= current_tab then
        state.floating = { buf = -1, win = -1, job_id = nil }
        state.cwd = nil
        state.tabpage = current_tab
    end

    if
        not is_valid_buf(state.floating.buf)
        or vim.bo[state.floating.buf].buftype ~= 'terminal'
    then
        local shell_cmd = get_shell_cmd()
        local item = create_floating_window({ buf = state.floating.buf })

        local job_id = vim.fn.termopen(shell_cmd, {
            cwd = vim.fn.getcwd(),
            on_exit = function(_, code, _)
                if code ~= 0 then
                    vim.schedule(function()
                        vim.notify(
                            'Floatterminal shell exited with code ' .. code,
                            vim.log.levels.DEBUG
                        )
                    end)
                end
            end,
        })

        item.job_id = job_id
        state.floating = item
        state.cwd = vim.fn.getcwd()

        set_terminal_keymaps(item.buf)
        vim.cmd('startinsert')
    else
        local item = create_floating_window({
            buf = state.floating.buf,
            job_id = state.floating.job_id,
        })
        state.floating = item
        vim.cmd('startinsert')
    end

    return state.floating
end

--- Ensure a sidebar terminal buffer exists (per tabpage) and is shown.
---@return FloatTermStateItem
local function ensure_sidebar_terminal()
    local current_tab = vim.api.nvim_get_current_tabpage()
    if state.sidebar_tabpage ~= current_tab then
        state.sidebar = { buf = -1, win = -1, job_id = nil }
        state.sidebar_tabpage = current_tab
    end

    if
        not is_valid_buf(state.sidebar.buf)
        or vim.bo[state.sidebar.buf].buftype ~= 'terminal'
    then
        local shell_cmd = get_shell_cmd()
        local item = create_sidebar_window({ buf = state.sidebar.buf })

        local job_id = vim.fn.termopen(shell_cmd, {
            cwd = vim.fn.getcwd(),
            on_exit = function(_, code, _)
                if code ~= 0 then
                    vim.schedule(function()
                        vim.notify(
                            'Sidebar terminal shell exited with code ' .. code,
                            vim.log.levels.DEBUG
                        )
                    end)
                end
            end,
        })

        item.job_id = job_id
        state.sidebar = item

        set_terminal_keymaps(item.buf)
        vim.cmd('startinsert')
    else
        -- Buffer already has a terminal — reuse it in a new split window
        local item = create_sidebar_window({
            buf = state.sidebar.buf,
            job_id = state.sidebar.job_id,
        })
        state.sidebar = item
        vim.cmd('startinsert')
    end

    return state.sidebar
end

----------------------------------------------------------------------
-- Public: toggle / open / close
----------------------------------------------------------------------

function M.toggle()
    if not is_valid_win(state.floating.win) then
        ensure_terminal()
        return
    end

    local cur_win = vim.api.nvim_get_current_win()
    local wins = vim.api.nvim_tabpage_list_wins(0)

    if cur_win == state.floating.win and #wins == 1 then
        -- Only window: check if job is active before force-closing
        if is_valid_buf(state.floating.buf) then
            if has_active_job(state.floating.buf) then
                vim.notify(
                    'Terminal has active job running. Press again to force close.',
                    vim.log.levels.WARN
                )
                -- Store timestamp for double-press detection
                if
                    not state.last_close_attempt
                    or (vim.loop.now() - state.last_close_attempt) > 2000
                then
                    state.last_close_attempt = vim.loop.now()
                    return
                end
            end
            vim.api.nvim_buf_delete(state.floating.buf, { force = true })
        end
        state.floating = { buf = -1, win = -1, job_id = nil }
        state.last_close_attempt = nil
        return
    end

    vim.api.nvim_win_hide(state.floating.win)
end

function M.open()
    ensure_terminal()
end

function M.hide()
    if is_valid_win(state.floating.win) then
        vim.api.nvim_win_hide(state.floating.win)
    end
end

function M.toggle_sidebar()
    if not is_valid_win(state.sidebar.win) then
        ensure_sidebar_terminal()
        return
    end

    local cur_win = vim.api.nvim_get_current_win()
    local wins = vim.api.nvim_tabpage_list_wins(0)

    if cur_win == state.sidebar.win and #wins == 1 then
        -- Last window — guard against accidental close if job is active
        if is_valid_buf(state.sidebar.buf) then
            if has_active_job(state.sidebar.buf) then
                vim.notify(
                    'Sidebar terminal has active job running. Press again to force close.',
                    vim.log.levels.WARN
                )
                if
                    not state.sidebar_last_close_attempt
                    or (vim.loop.now() - state.sidebar_last_close_attempt)
                        > 2000
                then
                    state.sidebar_last_close_attempt = vim.loop.now()
                    return
                end
            end
            vim.api.nvim_buf_delete(state.sidebar.buf, { force = true })
        end
        state.sidebar = { buf = -1, win = -1, job_id = nil }
        state.sidebar_last_close_attempt = nil
        return
    end

    vim.api.nvim_win_hide(state.sidebar.win)
end

function M.open_sidebar()
    ensure_sidebar_terminal()
end

function M.hide_sidebar()
    if is_valid_win(state.sidebar.win) then
        vim.api.nvim_win_hide(state.sidebar.win)
    end
end

----------------------------------------------------------------------
-- Setup
----------------------------------------------------------------------

---@param opts? { keymap?: string|false, sidebar_keymap?: string|false }
function M.setup(opts)
    opts = opts or {}

    -- Float terminal keymap
    local keymap = opts.keymap
    if keymap == nil then
        keymap = '<M-t>'
    end

    if
        not pcall(vim.api.nvim_get_commands, { builtin = false })
        or not vim.api.nvim_get_commands({})['Floatterminal']
    then
        vim.api.nvim_create_user_command('Floatterminal', function()
            M.toggle()
        end, {})
    end

    if keymap and keymap ~= false then
        vim.keymap.set({ 'n', 't' }, keymap, function()
            M.toggle()
        end, { noremap = true, desc = 'Toggle floating terminal' })
    end

    -- Sidebar terminal keymap
    local sidebar_keymap = opts.sidebar_keymap
    if sidebar_keymap == nil then
        sidebar_keymap = '<M-s>'
    end

    if
        not pcall(vim.api.nvim_get_commands, { builtin = false })
        or not vim.api.nvim_get_commands({})['FloatterminalSidebar']
    then
        vim.api.nvim_create_user_command('FloatterminalSidebar', function()
            M.toggle_sidebar()
        end, {})
    end

    if sidebar_keymap and sidebar_keymap ~= false then
        vim.keymap.set({ 'n', 't' }, sidebar_keymap, function()
            M.toggle_sidebar()
        end, { noremap = true, desc = 'Toggle sidebar terminal' })
    end
end

return M
