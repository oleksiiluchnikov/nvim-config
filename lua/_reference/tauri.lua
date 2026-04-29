local Path = require('plenary.path')
local run_commands = {
    dev = 'npm run tauri dev',
    build = 'npm run tauri build',
}

-- Initialize an empty table for the Tauri package.
package.loaded.tauri = {}

--- Get the Tauri project root directory.
--- Stores the Tauri project root in the global variable package.loaded.tauri.root.
local function get_tauri_root()
    local dir = vim.fn.expand('%:p:h')
    local path = Path:new(dir)
    -- Only call this function again if the current buffer is in a different Tauri project directory.
    if
        package.loaded.tauri.root
        and package.loaded.tauri.root == path.filename
    then
        return package.loaded.tauri.root
    end
    -- Iterate through parent directories until reaching the root directory ('/')
    while path.filename ~= '/' do
        if Path:new(path.filename, 'src-tauri'):exists() then
            package.loaded.tauri.root = path.filename
            return package.loaded.tauri.root
        end
        -- Move to the parent directory
        path = path:parent()
    end
    package.loaded.tauri.root = nil
end

--- Check if the current directory is a Tauri project.
local function is_tauri_project()
    -- Call get_tauri_root() to ensure the global variable package.loaded.tauri.root is set.
    get_tauri_root()
    if package.loaded.tauri.root == nil then
        vim.notify('Not a Tauri project', vim.log.levels.ERROR)
        return false
    end
    return true
end

--- Change the current directory to the Tauri project root.
local function cd_to_tauri_root()
    -- cd to the Tauri project root
    vim.cmd('cd ' .. get_tauri_root())
end

--- Change the current directory to the Tauri project frontend directory.
local function cd_to_tauri_frontend()
    -- cd to the Tauri project frontend directory
    vim.cmd('cd ' .. get_tauri_root() .. '/src')
end

--- Change the current directory to the Tauri project backend directory.
local function cd_to_tauri_backend()
    -- cd to the Tauri project backend directory
    vim.cmd('cd ' .. get_tauri_root() .. '/src-tauri/src')
end

--- TauriDev user command to run Tauri development server.
vim.api.nvim_create_user_command('TauriDev', function()
    if is_tauri_project() == false then
        return
    end
    -- cd to the Tauri project root
    cd_to_tauri_root()
    vim.cmd('split | terminal ' .. run_commands.dev)
end, {})

--- TauriBuild user command to build a Tauri project.
vim.api.nvim_create_user_command('TauriBuild', function()
    if is_tauri_project() == false then
        return
    end
    -- cd to the Tauri project root
    cd_to_tauri_root()
    vim.cmd('split | terminal ' .. run_commands.build)
end, {})

--- TauriFrontend user command to search Tauri project frontend files.
vim.api.nvim_create_user_command('TauriFrontend', function()
    if is_tauri_project() == false then
        return
    end
    -- cd to the Tauri project root
    cd_to_tauri_frontend()
    require('telescope.builtin').find_files({
        prompt_title = 'Tauri Frontend',
        cwd = get_tauri_root() .. '/src',
    })
end, {})

--- TauriBackend user command to search Tauri project backend files.
vim.api.nvim_create_user_command('TauriBackend', function()
    if is_tauri_project() == false then
        return
    end
    -- cd to the Tauri project root
    cd_to_tauri_backend()
    require('telescope.builtin').find_files({
        prompt_title = 'Tauri Backend',
        cwd = get_tauri_root() .. '/src-tauri/src',
    })
end, {})

--- TauriConfig user command to open Tauri project configuration file.
vim.api.nvim_create_user_command('TauriConfig', function()
    if is_tauri_project() == false then
        return
    end
    -- cd to the Tauri project root
    cd_to_tauri_backend()
    vim.cmd('e ' .. get_tauri_root() .. '/src-tauri/tauri.conf.json')
end, {})

--- TauriCargo user command to open Tauri project Cargo.toml file.
vim.api.nvim_create_user_command('TauriCargo', function()
    if is_tauri_project() == false then
        return
    end
    -- cd to the Tauri project root
    cd_to_tauri_backend()
    vim.cmd('e ' .. get_tauri_root() .. '/src-tauri/Cargo.toml')
end, {})

--- TauriMain user command to open Tauri project main.rs file.
vim.api.nvim_create_user_command('TauriMain', function()
    if is_tauri_project() == false then
        return
    end
    -- cd to the Tauri project root
    cd_to_tauri_backend()
    vim.cmd('e ' .. get_tauri_root() .. '/src-tauri/src/main.rs')
end, {})
run_commands = {
    dev = 'npm run tauri dev',
    build = 'npm run tauri build',
}

-- Initialize an empty table for the Tauri package.
package.loaded.tauri = {}

--- TauriDev user command to run Tauri development server.
vim.api.nvim_create_user_command('TauriDev', function()
    if is_tauri_project() == false then
        return
    end
    -- cd to the Tauri project root
    cd_to_tauri_root()
    vim.cmd('split | terminal ' .. run_commands.dev)
end, {})

--- TauriBuild user command to build a Tauri project.
vim.api.nvim_create_user_command('TauriBuild', function()
    if is_tauri_project() == false then
        return
    end
    -- cd to the Tauri project root
    cd_to_tauri_root()
    vim.cmd('split | terminal ' .. run_commands.build)
end, {})

--- TauriFrontend user command to search Tauri project frontend files.
vim.api.nvim_create_user_command('TauriFrontend', function()
    if is_tauri_project() == false then
        return
    end
    -- cd to the Tauri project root
    cd_to_tauri_frontend()
    require('telescope.builtin').find_files({
        prompt_title = 'Tauri Frontend',
        cwd = get_tauri_root() .. '/src',
    })
end, {})

--- TauriBackend user command to search Tauri project backend files.
vim.api.nvim_create_user_command('TauriBackend', function()
    if is_tauri_project() == false then
        return
    end
    -- cd to the Tauri project root
    cd_to_tauri_backend()
    require('telescope.builtin').find_files({
        prompt_title = 'Tauri Backend',
        cwd = get_tauri_root() .. '/src-tauri/src',
    })
end, {})

--- TauriConfig user command to open Tauri project configuration file.
vim.api.nvim_create_user_command('TauriConfig', function()
    if is_tauri_project() == false then
        return
    end
    -- cd to the Tauri project root
    cd_to_tauri_backend()
    vim.cmd('e ' .. get_tauri_root() .. '/src-tauri/tauri.conf.json')
end, {})

--- TauriCargo user command to open Tauri project Cargo.toml file.
vim.api.nvim_create_user_command('TauriCargo', function()
    if is_tauri_project() == false then
        return
    end
    -- cd to the Tauri project root
    cd_to_tauri_backend()
    vim.cmd('e ' .. get_tauri_root() .. '/src-tauri/Cargo.toml')
end, {})

--- TauriMain user command to open Tauri project main.rs file.
vim.api.nvim_create_user_command('TauriMain', function()
    if is_tauri_project() == false then
        return
    end
    -- cd to the Tauri project root
    cd_to_tauri_backend()
    vim.cmd('e ' .. get_tauri_root() .. '/src-tauri/src/main.rs')
end, {})
