--[[
    INIT.LUA - Beyond Expert Level Configuration
    Architecture: Priority-First Loader with Chain of Responsibility for AI
    Performance:  Optimized via Upvalue Caching and Lazy Evaluation
--]]

---@diagnostic disable: undefined-field

-- 1. PRE-FLIGHT CHECKS & RESOURCE OPTIMIZATION
-- Disable unnecessary providers immediately to save startup time and RAM.
-- Using a table iteration for cleanliness and expandability.
for _, provider in ipairs({ 'ruby', 'perl', 'node' }) do
    vim.g['loaded_' .. provider .. '_provider'] = 0
end

-- 2. THE SAFE LOADER PATTERN
-- A protected wrapper that isolates module failures preventing complete config crashes.
---@param module_name string
---@return boolean status
local function safe_load(module_name)
    local status, err = pcall(require, module_name)
    if not status then
        -- Schedule notification to not block the UI thread during startup
        vim.schedule(function()
            vim.notify(
                string.format(
                    '❌ Failed to load \'%s\':\n%s',
                    module_name,
                    err
                ),
                vim.log.levels.ERROR,
                { title = 'Config Loader' }
            )
        end)
    end
    return status
end

-- 3. PRIORITY MODULE LOADING
-- Critical components are loaded explicitly to ensure correct dependency order.
local core_modules = {
    'config.options',
    -- 'config.mappings',
    'config.lazy', -- Plugin manager must initialize early
    'config.autocmds',
    'config.utils',
}

local loaded_modules = {}
for _, mod in ipairs(core_modules) do
    if safe_load(mod) then
        loaded_modules[mod] = true
    end
end

-- 4. DYNAMIC MODULE DISCOVERY (The "Extendable" Part)
-- Scans the config directory for any auxiliary files not manually listed above.
local config_path = vim.fn.stdpath('config') .. '/lua/config'
local fs_handle = vim.loop.fs_scandir(config_path)

if fs_handle then
    while true do
        local name, type = vim.loop.fs_scandir_next(fs_handle)
        if not name then
            break
        end

        -- Filter: Lua files only, ignore init.lua, ignore already loaded core modules
        if type == 'file' and name:match('%.lua$') and name ~= 'init.lua' then
            local mod_name = 'config.' .. name:sub(1, -5)
            if not loaded_modules[mod_name] then
                safe_load(mod_name)
            end
        end
    end
end

-- Load specific utilities that might be standalone
-- safe_load('config.utils.floatterminal')
require('config.utils.floatterminal').setup()

-- 5. ASYNCHRONOUS UI SETUP
-- Defer heavy UI loads (like colorschemes) to allow the UI to render the first frame faster.
vim.schedule(function()
    vim.cmd('silent! colorscheme catppuccin')
end)

-- ============================================================================
--  6. AI COMPLETION ENGINE (Chain of Responsibility)
--  Optimized for "Blazingly Fast" execution by caching providers at startup.
-- ============================================================================

---@class CompletionAgent
---@field name string
---@field available boolean
---@field accept function -- Accepts partial/word
---@field accept_full function -- Accepts the whole suggestion

-- local AI = {}

-- Helper to normalize termcodes (cached)
local term_tab = vim.api.nvim_replace_termcodes('<Tab>', true, true, true)

---@return boolean
local function is_whitespace_preceding()
    local col = vim.fn.col('.') - 1
    return col == 0 or vim.fn.getline('.'):sub(col, col):match('%s') ~= nil
end

-- Define Agents (Blink, Supermaven, Copilot Lua, Copilot Vim, Avante)
-- We check availability ONCE during startup, not every keypress.

local agents = {
    blink = {
        available = pcall(require, 'blink.cmp'),
        module = package.loaded['blink.cmp'],
    },
    supermaven = {
        available = pcall(require, 'supermaven-nvim.completion_preview'),
        module = package.loaded['supermaven-nvim.completion_preview'],
    },
    avante = {
        available = pcall(require, 'avante.api'),
        module = package.loaded['avante.api'],
    },
    copilot_lua = {
        available = pcall(require, 'copilot.suggestion'),
        module = package.loaded['copilot.suggestion'],
    },
    copilot_vim = {
        available = vim.fn.exists('*copilot#Accept') == 1,
    },
}

-- Construct the Accept Strategy
---@param mode 'word' | 'full'
local function accept_ai_suggestion(mode)
    -- 1. Blink CMP (Menu priority)
    if agents.blink.available and agents.blink.module.is_menu_visible() then
        return agents.blink.module.accept()
    end

    if
        agents.copilot_lua.available and agents.copilot_lua.module.is_visible()
    then
        if mode == 'word' then
            return agents.copilot_lua.module.accept_word()
        else
            return agents.copilot_lua.module.accept()
        end
    end

    -- 2. Supermaven
    if
        agents.supermaven.available
        and agents.supermaven.module.has_suggestion()
    then
        if mode == 'word' then
            return agents.supermaven.module.on_accept_suggestion_word()
        else
            return agents.supermaven.module.on_accept_suggestion()
        end
    end

    -- 3. Avante
    if agents.avante.available then
        local suggestion = agents.avante.module.get_suggestion()
        if suggestion and suggestion:is_visible() then
            return suggestion:accept()
        end
    end

    -- 4. Copilot (Lua)

    -- 5. Copilot (Vimscript Legacy)
    if agents.copilot_vim.available then
        local key = vim.fn['copilot#Accept']('')
        if key ~= '' then
            return vim.api.nvim_feedkeys(key, 'i', true)
        end
    end

    -- 6. Fallback (Indent/Tab)
    -- Only performed if no AI suggestion was found
    if is_whitespace_preceding() then
        return vim.fn.feedkeys(term_tab, 'n')
    end

    -- Return true to indicate fallback to default behavior if mapped
    return true
end

-- ============================================================================
--  7. EXPERT KEYMAPPINGS
-- ============================================================================

-- Window Focus (Fast switching)
vim.keymap.set('n', '<Left>', '<C-w>h', { desc = 'Focus Left' })
vim.keymap.set('n', '<Right>', '<C-w>l', { desc = 'Focus Right' })

-- AI Accept (Word/Partial)
vim.keymap.set({ 'n', 'i', 'c', 't' }, '<C-y>', function()
    accept_ai_suggestion('word')
end, { desc = 'AI: Accept Word/Selection' })

-- AI Accept (Full Line/Block)
vim.keymap.set({ 'n', 'i', 'c', 't' }, '<C-j>', function()
    accept_ai_suggestion('full')
end, { desc = 'AI: Accept Full Suggestion' })

-- Context-Aware Navigation
-- Moves selection in menu if open, otherwise smart-jumps code blocks.
local function smart_nav(direction)
    local is_down = direction == 'down'

    -- Check Blink
    if agents.blink.available and agents.blink.module.is_menu_visible() then
        return is_down and agents.blink.module.select_next()
            or agents.blink.module.select_prev()
    end

    -- Fallback to smart buffer jump
    -- We use pcall here in case config.utils.buf isn't loaded correctly
    local ok, buf_utils = pcall(require, 'config.utils.buf')
    if ok and buf_utils.jump_to_next_line_with_same_indent then
        buf_utils.jump_to_next_line_with_same_indent(is_down, { 'end', '-' })
    else
        -- Ultimate fallback to standard movement if utils fail
        local key = is_down and 'j' or 'k'
        vim.cmd('norm! ' .. key)
    end
end

-- Detect server mode
local function is_remote_ui()
    local servername = vim.v.servername
    return servername and servername:match('/tmp/nvim%-server%.sock')
end

if is_remote_ui() then
    -- Function to close the Ghostty window
    local function close_ghostty_window()
        -- Try yabai first (fastest)
        local success = os.execute([[
            window_id=$(yabai -m query --windows --window | jq -r '.id')
            [ -n "$window_id" ] && [ "$window_id" != "null" ] && yabai -m window --close "$window_id"
        ]]) == 0

        if not success then
            -- Fallback to AppleScript
            os.execute(
                [[osascript -e 'tell application "System Events" to tell process "Ghostty" to keystroke "w" using command down']]
            )
        end
    end

    -- Override :q to close window (with proper error handling)
    vim.api.nvim_create_user_command('Q', function()
        -- Try to close window first
        local ok, _ = pcall(function()
            vim.cmd('close')
        end)

        if not ok then
            -- Can't close window (probably last one), try buffer delete
            local buf_count = #vim.fn.getbufinfo({ buflisted = 1 })

            if buf_count > 1 then
                vim.cmd('bdelete')
            else
                -- Last buffer - close the Ghostty window
                vim.notify('Closing window...', vim.log.levels.INFO)
                vim.defer_fn(close_ghostty_window, 50)
            end
        end
    end, { desc = 'Safe quit' })

    -- Commands
    vim.api.nvim_create_user_command(
        'QuitUI',
        close_ghostty_window,
        { desc = 'Close window' }
    )
    vim.api.nvim_create_user_command(
        'QuitServer',
        'confirm qall',
        { desc = 'Stop server' }
    )

    -- Remaps
    vim.cmd([[
        cnoreabbrev <expr> q (getcmdtype() == ':' && getcmdline() == 'q') ? 'Q' : 'q'
        cnoreabbrev <expr> quit (getcmdtype() == ':' && getcmdline() == 'quit') ? 'Q' : 'quit'
        cnoreabbrev <expr> wq (getcmdtype() == ':' && getcmdline() == 'wq') ? 'w<bar>Q' : 'wq'
        cnoreabbrev <expr> qa (getcmdtype() == ':' && getcmdline() == 'qa') ? 'Q' : 'qa'
    ]])

    -- ZZ/ZQ
    vim.keymap.set('n', 'ZZ', function()
        vim.cmd('write')
        close_ghostty_window()
    end, { desc = 'Save and close window' })

    vim.keymap.set('n', 'ZQ', close_ghostty_window, { desc = 'Close window' })
end

require('scripts.diagnostics').setup()
require('plugins.telescope.pickers')

require('config.utils.string_preview')

-- Add keymaps
vim.keymap.set('n', '<leader>es', function()
    require('config.utils.string_preview').edit_string()
end, { desc = 'Edit String' })

-- Or create a command
vim.api.nvim_create_user_command('EditString', function()
    require('config.string_preview').edit_string()
end, { desc = 'Edit long string in floating window' })

-- Setup telescope highlights after colorscheme
vim.api.nvim_create_autocmd('ColorScheme', {
    pattern = '*',
    callback = function()
        local ok, pickers = pcall(require, 'plugins.telescope.pickers')
        if ok and pickers.setup_highlights then
            vim.defer_fn(pickers.setup_highlights, 50)
        end
    end,
    desc = 'Setup telescope highlights after colorscheme change',
})

vim.keymap.set({ 'n', 'i', 'v' }, '<Up>', function()
    smart_nav('up')
end, { desc = 'Smart Up' })
vim.keymap.set({ 'n', 'i', 'v' }, '<Down>', function()
    smart_nav('down')
end, { desc = 'Smart Down' })

vim.keymap.set({ 'n', 'i', 'v' }, '<C-Down>', function()
    smart_nav('down')
end, { desc = 'Smart Down (C-Down)' })

vim.keymap.set({ 'n', 'v' }, '<leader>j', function()
    vim.cmd([[CodeCompanionChat]])
end, { desc = 'Toggle a chat buffer' })

vim.keymap.set({ 'n', 'v' }, '<leader>x', function()
    vim.cmd([[CodeCompanionChat Add]])
end, { desc = 'Add code to a chat buffer' })

-- vim.keymap.set('n', '<leader>m', function()
--     require('telescope.builtin').keymaps(
--         require('telescope.themes').get_dropdown({
--             prompt_title = 'Keymaps',
--             layout_config = {
--                 height = 0.4,
--                 width = 0.6,
--             },
--             previewer = false,
--         })
--     )
-- end, { desc = 'Show Keymaps' })

vim.keymap.set('n', '<leader>cd', function()
    local root = vim.fn.expand('%:p:h') -- Get the directory of the current file
    -- Remove oil: prefix from oil.nvim if it exists
    root = root:gsub('^oil://', '')

    if root and root ~= '' then
        vim.cmd('cd ' .. vim.fn.fnameescape(root)) -- Change directory to the root
        -- Display a notification with the new directory
        vim.notify('Changed directory to: ' .. root, vim.log.levels.INFO, {
            timeout = 1500, -- Set a longer timeout for better readability
        })
    else
        -- Show a warning if the directory can't be determined
        vim.notify(
            'Could not determine a valid root directory.',
            vim.log.levels.WARN,
            {
                timeout = 1500,
            }
        )
    end
end, { desc = 'Change to the project root directory' })

-- Send Make commond
vim.keymap.set('n', '<leader>m', function()
    vim.cmd('!make test')
end, { desc = 'Run Make Test' })
