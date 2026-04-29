--[[
    AI Completion Engine
    Priority: Codeium → Supermaven → Avante → Blink Menu → Tab Fallback
    Performance: Agent modules cached at startup (zero pcall overhead)

    NOTE: Codeium virtual_text accept functions are *expr* mappings — they
    return raw keystrokes.  We feed them through nvim_feedkeys with 'n' flag.
--]]

local M = {}

-- Cached termcodes
local term_tab = vim.api.nvim_replace_termcodes('<Tab>', true, true, true)

---@return boolean
local function is_whitespace_preceding()
    local col = vim.fn.col('.') - 1
    return col == 0 or vim.fn.getline('.'):sub(col, col):match('%s') ~= nil
end

--- Lazily resolve a module: try package.loaded first, then require.
---@param name string
---@return table|nil
local function lazy_mod(name)
    if package.loaded[name] then
        return package.loaded[name]
    end
    local ok, mod = pcall(require, name)
    if ok then
        return mod
    end
    return nil
end

--- Feed expr-mapping keys returned by codeium virtual_text functions.
---@param keys string raw key sequence from an expr function
local function feed_expr(keys)
    if keys and keys ~= '' then
        local replaced =
            vim.api.nvim_replace_termcodes(keys, true, true, true)
        vim.api.nvim_feedkeys(replaced, 'n', true)
    end
end

---@param mode 'word' | 'full' | 'line'
function M.accept_suggestion(mode)
    -- Priority 1: Codeium virtual text (expr-style API)
    local codeium = lazy_mod('codeium.virtual_text')
    if codeium then
        local status = codeium.status()
        if status.state == 'completions' and status.total > 0 then
            if mode == 'word' then
                feed_expr(codeium.accept_next_word())
            elseif mode == 'line' then
                feed_expr(codeium.accept_next_line())
            else
                feed_expr(codeium.accept())
            end
            return
        end
    end

    -- Priority 2: Supermaven (fastest)
    local supermaven = lazy_mod('supermaven-nvim.completion_preview')
    if supermaven and supermaven.has_suggestion() then
        if mode == 'word' then
            supermaven.on_accept_suggestion_word()
        else
            -- Supermaven doesn't have accept_line, use full
            supermaven.on_accept_suggestion()
        end
        return
    end

    -- Priority 3: Avante (bulletproof error handling)
    local avante = lazy_mod('avante.api')
    if avante then
        local ok, suggestion = pcall(avante.get_suggestion)
        if
            ok
            and suggestion
            and type(suggestion.is_visible) == 'function'
            and suggestion:is_visible()
        then
            if type(suggestion.accept) == 'function' then
                suggestion:accept()
                return
            end
        end
    end

    -- Priority 4: Blink Menu (if visible, accept selection)
    local blink = lazy_mod('blink.cmp')
    if blink and blink.is_visible() then
        blink.accept()
        return
    end

    -- Fallback: Tab indentation
    if is_whitespace_preceding() then
        vim.fn.feedkeys(term_tab, 'n')
    end
end

-- Cache buf_utils module for smart_nav (loaded once)
local buf_utils = package.loaded['config.lib.buf']
if not buf_utils then
    pcall(function()
        buf_utils = require('config.lib.buf')
    end)
end

-- Context-Aware Navigation (Blink menu or smart buffer jump)
function M.smart_nav(direction)
    local is_down = direction == 'down'

    -- Check Blink menu
    local blink = lazy_mod('blink.cmp')
    if blink and blink.is_visible() then
        return is_down and blink.select_next() or blink.select_prev()
    end

    -- Fallback to smart buffer jump (using cached buf_utils)
    if buf_utils and buf_utils.jump_to_next_line_with_same_indent then
        buf_utils.jump_to_next_line_with_same_indent(is_down, { 'end', '-' })
    else
        -- Ultimate fallback to standard movement
        local key = is_down and 'j' or 'k'
        vim.cmd('norm! ' .. key)
    end
end

return M
