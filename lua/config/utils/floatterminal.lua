--- Floating terminal utilities.
--- LSP-friendly module with explicit exports.

local M = {}

---@class FloatTermStateItem
---@field buf integer
---@field win integer

---@class FloatTermState
---@field floating FloatTermStateItem
---@field cwd string|nil
---@field tabpage integer|nil

---@type FloatTermState
local state = {
    floating = {
        buf = -1,
        win = -1,
    },
    cwd = nil,
    tabpage = nil,
}

----------------------------------------------------------------------
-- Config
----------------------------------------------------------------------

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
    -- vim.o.lines/columns include cmdheight; we ignore cmdheight for centering.
    return vim.o.columns, vim.o.lines
end

--- Create (or reuse) a centered floating window.
---@param opts? { width?: integer, height?: integer, buf?: integer }
---@return FloatTermStateItem
local function create_floating_window(opts)
    opts = opts or {}
    local columns, lines = get_editor_size()

    local width = opts.width or math.floor(columns * 0.7)
    local height = opts.height or math.floor(lines * 0.9)

    -- clamp sizes to a minimum
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
    return { buf = buf, win = win }
end

----------------------------------------------------------------------
-- Terminal keymaps & UX
----------------------------------------------------------------------

---@param bufnr integer
local function set_terminal_keymaps(bufnr)
    local opts = { buffer = bufnr, noremap = true }

    -- Classic: leave terminal mode
    vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', opts)

    -- Common Zsh-like keybindings
    vim.keymap.set('t', '<C-a>', '<Home>', opts)
    vim.keymap.set('t', '<C-e>', '<End>', opts)
    vim.keymap.set('t', '<C-w>', '<C-\\><C-n>dbi', opts)
    vim.keymap.set('t', '<C-u>', '<C-\\><C-n>d0i', opts)
    vim.keymap.set('t', '<M-b>', '<C-\\><C-n>bi', opts)
    vim.keymap.set('t', '<M-f>', '<C-\\><C-n>wi', opts)

    -- History navigation
    vim.keymap.set('t', '<C-p>', '<Up>', opts)
    vim.keymap.set('t', '<C-n>', '<Down>', opts)

    -- Special keys
    vim.keymap.set('t', '<C-h>', '<BS>', opts)
    vim.keymap.set('t', '<C-?>', '<BS>', opts)

    -- Word movement with Ctrl+Arrow keys
    vim.keymap.set('t', '<C-Left>', '<C-\\><C-n>bi', opts)
    vim.keymap.set('t', '<C-Right>', '<C-\\><C-n>wi', opts)

    -- Meta mappings (Alt as a replacement for CMD)
    vim.keymap.set('t', '<M-w>', '<C-\\><C-n>', opts)
    vim.keymap.set('t', '<M-k>', '<C-\\><C-n>:Floatterminal<CR>', opts)
    vim.keymap.set('t', '<M-d>', '<C-\\><C-n>:hide<CR>', opts)

    -- Experimental: simple internal command palette for the terminal buffer.
    -- Press <M-p> in terminal to choose a common project command.
    vim.keymap.set('t', '<M-p>', function()
        vim.cmd([[stopinsert]])
        local builtins = {
            'git status',
            'git diff',
            'ls',
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

--- Determine shell command to use for this floatterminal.
--- Priority:
--- 1. .nvim-shell executable in project root
--- 2. $SHELL
--- 3. sh
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
    -- if we switched tabpage, reset state so each tab has its own float term
    local current_tab = vim.api.nvim_get_current_tabpage()
    if state.tabpage ~= current_tab then
        state.floating = { buf = -1, win = -1 }
        state.cwd = nil
        state.tabpage = current_tab
    end

    if
        not is_valid_buf(state.floating.buf)
        or vim.bo[state.floating.buf].buftype ~= 'terminal'
    then
        local shell_cmd = get_shell_cmd()
        local item = create_floating_window({ buf = state.floating.buf })

        -- open terminal and remember buf
        vim.fn.termopen(shell_cmd, {
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

        state.floating = item
        state.cwd = vim.fn.getcwd()

        -- apply keymaps
        set_terminal_keymaps(item.buf)
        vim.cmd('startinsert')
    else
        -- terminal buffer exists, just recreate / focus its window
        local item = create_floating_window({ buf = state.floating.buf })
        state.floating = item
        vim.cmd('startinsert')
    end

    return state.floating
end

----------------------------------------------------------------------
-- Public: toggle / open / close
----------------------------------------------------------------------

--- Toggle the floating terminal:
--- - If no terminal exists: create one.
--- - If window is hidden/invalid: reopen it.
--- - If window is visible:
---   * if it's the only window in the tabpage, close the terminal buffer
---   * otherwise just hide the window.
function M.toggle()
    if not is_valid_win(state.floating.win) then
        ensure_terminal()
        return
    end

    local cur_win = vim.api.nvim_get_current_win()
    local wins = vim.api.nvim_tabpage_list_wins(0)

    if cur_win == state.floating.win and #wins == 1 then
        -- Only window: close the buffer entirely
        if is_valid_buf(state.floating.buf) then
            vim.api.nvim_buf_delete(state.floating.buf, { force = true })
        end
        state.floating = { buf = -1, win = -1 }
        return
    end

    vim.api.nvim_win_hide(state.floating.win)
end

--- Explicitly open/focus the floating terminal.
function M.open()
    ensure_terminal()
end

--- Explicitly hide the floating terminal window (if any).
function M.hide()
    if is_valid_win(state.floating.win) then
        vim.api.nvim_win_hide(state.floating.win)
    end
end

----------------------------------------------------------------------
-- Setup: user command and keymaps
----------------------------------------------------------------------

--- Setup user command + default keymaps.
--- Calling multiple times is safe.
---@param opts? { keymap?: string|false }
function M.setup(opts)
    opts = opts or {}
    local keymap = opts.keymap
    if keymap == nil then
        keymap = '<M-t>'
    end

    -- User command
    if
        not pcall(vim.api.nvim_get_commands, { builtin = false })
        or not vim.api.nvim_get_commands({})['Floatterminal']
    then
        vim.api.nvim_create_user_command('Floatterminal', function()
            M.toggle()
        end, {})
    end

    -- Default toggle mapping (normal + terminal mode)
    if keymap and keymap ~= false then
        vim.keymap.set({ 'n', 't' }, keymap, function()
            M.toggle()
        end, { noremap = true, desc = 'Toggle floating terminal' })
    end
end

return M
