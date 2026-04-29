--[[
    Keymaps: AI
    Codeium/Supermaven accept, smart navigation, and CodeCompanion bindings.
--]]

local ai = require('config.ai')

-- AI Accept Keymaps
-- NOTE: Exclude 'c' (cmdline) — AI suggestions don't appear there,
-- and this would override blink.cmp's <C-y> for cmdline completion.
vim.keymap.set({ 'n', 'i', 't' }, '<C-y>', function()
    ai.accept_suggestion('word')
end, { desc = 'AI: Accept Word' })

vim.keymap.set({ 'n', 'i', 't' }, '<C-j>', function()
    ai.accept_suggestion('full')
end, { desc = 'AI: Accept Full Suggestion' })

vim.keymap.set({ 'n', 'i', 't' }, '<C-l>', function()
    ai.accept_suggestion('line')
end, { desc = 'AI: Accept Line (Cursor to EOL)' })

-- Smart Navigation (Up/Down)
vim.keymap.set({ 'n', 'i', 'v' }, '<Up>', function()
    ai.smart_nav('up')
end, { desc = 'Smart Up' })

vim.keymap.set({ 'n', 'i', 'v' }, '<Down>', function()
    ai.smart_nav('down')
end, { desc = 'Smart Down' })

vim.keymap.set({ 'n', 'i', 'v' }, '<C-Down>', function()
    ai.smart_nav('down')
end, { desc = 'Smart Down (C-Down)' })

-- CodeCompanion
vim.keymap.set({ 'n', 'v' }, '<leader>cc', function()
    vim.cmd([[CodeCompanionChat]])
end, { desc = 'CodeCompanion: Toggle chat buffer' })

vim.keymap.set({ 'n', 'v' }, '<leader>x', function()
    vim.cmd([[CodeCompanionChat Add]])
end, { desc = 'CodeCompanion: Add selection to chat' })
