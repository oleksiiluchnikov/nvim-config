-- Auto-reload files (Obsidian-friendly) — extracted from config/autocmds.lua
-- To use, copy this back to config/autocmds.lua or require it.

-- Enable auto-read globally
-- vim.opt.autoread = true

-- Check for file changes more frequently
-- vim.opt.updatetime = 1000

-- Auto-reload on various events
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

-- For markdown files (Obsidian), be extra aggressive
-- vim.api.nvim_create_autocmd('BufEnter', {
--     pattern = '*.md',
--     callback = function()
--         vim.opt_local.autoread = true
--         vim.opt_local.swapfile = false
--         vim.cmd('silent! checktime')
--     end,
-- })

-- Auto-reload without asking when file changes
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

-- Notify after reload
-- vim.api.nvim_create_autocmd('FileChangedShellPost', {
--     pattern = '*',
--     callback = function()
--         vim.notify('File reloaded', vim.log.levels.INFO)
--     end,
-- })
