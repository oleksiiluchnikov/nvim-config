--- Floating terminal utilities.
--- LSP-friendly module with explicit exports.

local M = {}

---@class FloatTermStateItem
---@field buf integer
---@field win integer
---@field job_id integer|nil

---@class FloatTermState
---@field floating FloatTermStateItem
---@field cwd string|nil
---@field tabpage integer|nil

---@type FloatTermState
local state = {
    floating = {
        buf = -1,
        win = -1,
        job_id = nil,
    },
    cwd = nil,
    tabpage = nil,
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

    -- Quick hide/toggle
    vim.keymap.set(
        't',
        '<M-d>',
        '<C-\\><C-n>:lua require("floatterm").hide()<CR>',
        opts
    )

    -- CRITICAL: Ensure Tab and completion keys pass through to shell
    -- These override any global mappings from completion plugins
    vim.keymap.set('t', '<Tab>', '<Tab>', opts)
    vim.keymap.set('t', '<S-Tab>', '<S-Tab>', opts)
    vim.keymap.set('t', '<C-y>', '<C-y>', opts)
    vim.keymap.set('t', '<C-e>', '<C-e>', opts)
    vim.keymap.set('t', '<C-n>', '<C-n>', opts)
    vim.keymap.set('t', '<C-p>', '<C-p>', opts)
    vim.keymap.set('t', '<CR>', '<CR>', opts)
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

----------------------------------------------------------------------
-- Setup
----------------------------------------------------------------------

---@param opts? { keymap?: string|false }
function M.setup(opts)
    opts = opts or {}
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
end

return M
