--[[
    INIT.LUA - Beyond Expert Level Configuration
    Architecture: Modular Priority-First Loader
    Performance:  Optimized via Upvalue Caching and Lazy Evaluation
--]]

---@diagnostic disable: undefined-field

-- 1. PRE-FLIGHT CHECKS & RESOURCE OPTIMIZATION
for _, provider in ipairs({ 'ruby', 'perl', 'node' }) do
    vim.g['loaded_' .. provider .. '_provider'] = 0
end

-- 2. SAFE LOADER PATTERN
---@param module_name string
---@return boolean status
local function safe_load(module_name)
    local status, err = pcall(require, module_name)
    if not status then
        vim.schedule(function()
            vim.notify(
                string.format('❌ Failed to load \'%s\':\n%s', module_name, err),
                vim.log.levels.ERROR,
                { title = 'Config Loader' }
            )
        end)
    end
    return status
end

-- 3. PRIORITY MODULE LOADING
local core_modules = {
    'config.options',
    'config.lazy',
    'config.autocmds',
    'config.utils',
    'config.ui',
    'config.remote',
    'config.keymaps',
}

local loaded_modules = {}
for _, mod in ipairs(core_modules) do
    if safe_load(mod) then
        loaded_modules[mod] = true
    end
end

-- 4. DYNAMIC MODULE DISCOVERY
local config_path = vim.fn.stdpath('config') .. '/lua/config'
local fs_handle = vim.loop.fs_scandir(config_path)

if fs_handle then
    while true do
        local name, type = vim.loop.fs_scandir_next(fs_handle)
        if not name then
            break
        end

        if type == 'file' and name:match('%.lua$') and name ~= 'init.lua' then
            local mod_name = 'config.' .. name:sub(1, -5)
            if not loaded_modules[mod_name] then
                safe_load(mod_name)
            end
        end
    end
end
