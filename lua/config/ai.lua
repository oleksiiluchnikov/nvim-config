--[[
    AI Completion Engine
    Priority: Copilot → Supermaven → Avante → Blink Menu → Tab Fallback
    Performance: Agent modules cached at startup (zero pcall overhead)
--]]

local M = {}

-- Cached termcodes
local term_tab = vim.api.nvim_replace_termcodes('<Tab>', true, true, true)

---@return boolean
local function is_whitespace_preceding()
    local col = vim.fn.col('.') - 1
    return col == 0 or vim.fn.getline('.'):sub(col, col):match('%s') ~= nil
end

-- Agent availability check (happens once at startup)
local agents = {
    copilot = {
        available = pcall(require, 'copilot.suggestion'),
        mod = package.loaded['copilot.suggestion'],
    },
    supermaven = {
        available = pcall(require, 'supermaven-nvim.completion_preview'),
        mod = package.loaded['supermaven-nvim.completion_preview'],
    },
    avante = {
        available = pcall(require, 'avante.api'),
        mod = package.loaded['avante.api'],
    },
    blink = {
        available = pcall(require, 'blink.cmp'),
        mod = package.loaded['blink.cmp'],
    },
}

---@param mode 'word' | 'full' | 'line'
function M.accept_suggestion(mode)
    -- Priority 1: Copilot (smartest)
    if agents.copilot.available and agents.copilot.mod.is_visible() then
        if mode == 'word' then
            agents.copilot.mod.accept_word()
        elseif mode == 'line' then
            agents.copilot.mod.accept_line()
        else
            agents.copilot.mod.accept()
        end
        return
    end

    -- Priority 2: Supermaven (fastest)
    if
        agents.supermaven.available
        and agents.supermaven.mod.has_suggestion()
    then
        if mode == 'word' then
            agents.supermaven.mod.on_accept_suggestion_word()
        else
            -- Supermaven doesn't have accept_line, use full
            agents.supermaven.mod.on_accept_suggestion()
        end
        return
    end

    -- Priority 3: Avante (bulletproof error handling)
    if agents.avante.available and agents.avante.mod then
        local ok, suggestion = pcall(agents.avante.mod.get_suggestion)
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
    if agents.blink.available and agents.blink.mod.is_visible() then
        agents.blink.mod.accept()
        return
    end

    -- Fallback: Tab indentation
    if is_whitespace_preceding() then
        vim.fn.feedkeys(term_tab, 'n')
    end
end

-- Cache buf_utils module for smart_nav (loaded once)
local buf_utils = package.loaded['config.utils.buf']
if not buf_utils then
    pcall(function()
        buf_utils = require('config.utils.buf')
    end)
end

-- Context-Aware Navigation (Blink menu or smart buffer jump)
function M.smart_nav(direction)
    local is_down = direction == 'down'

    -- Check Blink menu
    if agents.blink.available and agents.blink.mod.is_visible() then
        return is_down and agents.blink.mod.select_next()
            or agents.blink.mod.select_prev()
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
