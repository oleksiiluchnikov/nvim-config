local M = {}
------------------------------------------------------------------------------
--- Toggle VimShell terminal window (:VimShell)
--- @description If terminal in any split is open, close it. If terminal is closed, open it in current split with (:vsplit | VimShell)
--- @usage functions.toggle_terminal()
--- @return nil
function M.toggle()
    local terminal = 'vimshell'
    local is_buf_exist = function()
        local buf_exist = false
        local shell_buf = vim.fn.bufnr(terminal) -- get vimshell buffer number
        if shell_buf ~= -1 then
            buf_exist = true
            return buf_exist
        end
        return buf_exist
    end
    local is_focused = function()
        local focused = false
        local current_win = vim.fn.win_getid() -- get current window id
        local current_buf = vim.fn.winbufnr(current_win) -- get current buffer number
        local shell_buf = vim.fn.bufnr(terminal) -- get vimshell buffer number
        if current_buf == shell_buf then
            focused = true
            return focused
        end
        return focused
    end

    local is_split_exist = function()
        local split_exist = false
        local shell_buf = vim.fn.bufnr(terminal) -- get vimshell buffer number
        local shell_win = vim.fn.bufwinid(shell_buf) -- get vimshell window id
        if shell_win ~= -1 then
            split_exist = true
            return split_exist
        end
        return split_exist
    end

    if is_buf_exist() then
        if is_split_exist() then
            if is_focused() then
                vim.cmd('q')
            else
                vim.cmd('wincmd p')
                vim.cmd('q')
            end
            return
        end
        vim.cmd('vsplit | VimShell')
    else
        vim.cmd('vsplit | VimShell')
    end
end
--- Open VimShell in floating window
--- @description Open VimShell in floating window
--- @usage functions.open_terminal()
--- @return nil
function M.open()
    -- functions.open_terminal()
    -- Function
    -- Open VimShell in floating window
    -- Parameters:
    -- * None

    local win = vim.fn.win_getid()
    local term = vim.fn.win_gettype(win)
    if term == 'terminal' then
        vim.cmd('q')
    else
        vim.cmd('VimShell')
    end
end

-- ---Exit VimShell terminal window (:VimShellPop)
-- ---@description Exit VimShell terminal window (:VimShellPop)
-- ---@usage functions.close_terminal()
-- function require('config.utils').close_terminal()
--     -- functions.close_terminal()
--     -- Function
--     -- Exit VimShell terminal window (:VimShellPop)
--     -- Parameters:
--     -- * None
--     -- Usage:
--     -- * <leader>te
--
--     -- find buffer with terminal
--     local terminal = 'vimshell'
--     -- local buffers = vim.api.nvim_list_bufs()
--     local is_exist = function(buf)
--         -- Function
--         -- Check if buffers vimshell is exists in buffers
--         -- Parameters:
--         -- * buf: buffer number
--
--         -- Return: boolean
--         return vim.fn.bufname(buf) == terminal -- bufname returns buffer name by number (buf)
--     end
--     -- local is_focused = function(buf)
--     -- Function
--     -- Check if buffer vimshell is focused
--     -- Parameters:
--     -- * buf: buffer number
--
--     -- Return: boolean
--     -- return vim.api.nvim_win_get_buf(0) == buf -- get current buffer number in current window and compare it with buffer number of vimshell buffer
--     -- end
--     if is_exist(vim.fn.bufnr(terminal)) then -- if vimshell is exists
--         vim.cmd('b ' .. terminal) -- focus it
--         vim.cmd('q') -- close it
--         return
--     else
--         return
--     end
-- end
return M
