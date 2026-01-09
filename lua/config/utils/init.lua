local M = {}
function P(v)
    local Popup = require('nui.popup')
    local text

    if type(v) == 'function' then
        local tbl = require('config.utils').get_function_source(v)

        if not tbl then
            vim.notify('Could not get function source', vim.log.levels.ERROR, {
                title = 'ERROR',
            })
            return nil
        end
        require('telescope.builtin').live_grep({
            default_text = tbl.func_name,
            search_dirs = { tbl.path_to_parent },
        })
        return nil
    end
    text = vim.inspect(v)

    ---@type nui_popup_options
    local win_config = {
        enter = true,
        relative = 'editor',
        focusable = true,
        border = {
            style = 'rounded',
        },
        position = '50%',
        size = {
            width = '80%',
            height = '90%',
        },
        buf_options = {
            buftype = '',
        },
        win_options = {
            winhighlight = 'Normal:Normal',
            number = true,
        },
    }

    local popup = Popup(win_config)
    popup:mount()
    if text:len() < 10000 then
        local dummy_filename = 'inspect.lua'
        local filetype = 'lua'
        vim.api.nvim_buf_set_name(popup.bufnr, dummy_filename)
        vim.api.nvim_set_option_value(
            'filetype',
            filetype,
            { buf = popup.bufnr }
        )
        vim.api.nvim_set_option_value('buftype', '', { buf = popup.bufnr })
    end
    vim.api.nvim_buf_set_lines(popup.bufnr, 0, -1, true, vim.split(text, '\n'))

    vim.api.nvim_set_option_value('modifiable', false, { buf = popup.bufnr })
    vim.api.nvim_set_option_value('readonly', true, { buf = popup.bufnr })

    local opts = { noremap = true, silent = true }
    vim.keymap.set('n', 'q', function()
        popup:unmount()
    end, opts)

    popup:on('BufLeave', function()
        popup:unmount()
    end)

    return v
end

function R(_package)
    package.loaded[_package] = nil
    return require(_package)
end

function T()
    print(require('nvim-treesitter.ts_utils').get_node_at_cursor():type())
end

--- Safe require for loading modules, with error handling
---@diagnostic disable: lowercase-global
function require_safe(module_name)
    -- macro around pcall to handle errors and send logs
    -- it uses pcall to require the module and, if it fails, it sends a log
    -- message to the user.
    local status_ok, module = pcall(require, module_name)
    if not status_ok then
        vim.notify(
            'loading ' .. module_name .. ' failed: ' .. module,
            vim.log.levels.WARN
        )
        return
    end
    return require(module_name)
end

--- Measures the execution time of a function and prints it to the Neovim command line.
---
--- This function takes a function as an argument, executes it, and measures the time it takes to complete.
--- The measured time is then printed to the Neovim command line, along with the provided name for the function.
---
--- @param name string -- The name or description of the function being benchmarked.
--- @param func function -- The function to be benchmarked.
---
--- @usage
--- ```lua
--- -- Example usage:
--- local function my_function()
---     -- Some time-consuming operation
---     vim.fn.sleep(1000)
--- end
---
--- require('config.utils').benchmark("My Function", my_function)
--- -- Output: "1.001s My Function"
--- ```
--- @return nil
function B(name, func)
    local start_time = vim.fn.reltime()
    func()
    local elapsed_time = vim.fn.reltimestr(vim.fn.reltime(start_time))
    vim.api.nvim_echo({ { elapsed_time .. ' ' .. name, 'String' } }, true, {})
end

-- Import UI utility functions for notifications and interface updates
M.ui = require('config.utils.ui')

-- Get formatted Neovim version string
-- Returns version with prerelease info if applicable (e.g., "0.11.0\ndev" or "0.10.1")
function M.version()
    local ver = vim.version()

    if ver.api_prerelease then
        return ver.major
            .. '.'
            .. ver.minor
            .. '.'
            .. ver.patch
            .. '\n'
            .. ver.prerelease
    else
        return ver.major .. '.' .. ver.minor .. '.' .. ver.patch
    end
end

-- Detect Linux distribution and version information
-- Tries /etc/os-release first, falls back to /etc/lsb-release
-- Returns formatted string like "Ubuntu 22.04.1 LTS" or "Linux (unknown version)"
function M.linux_os_info()
    -- Helper function to parse key=value files (handles quoted/unquoted values)
    local function parse_release_file(path, keys)
        local info = {}
        local f = io.open(path, 'r')
        if not f then
            return nil
        end
        -- Parse each line looking for key=value pairs
        for line in f:lines() do
            -- Try quoted values first: KEY="value"
            local k, v = line:match('^(%w+)%s*=%s*"(.-)"$')
            if not k then
                -- Fall back to unquoted: KEY=value
                k, v = line:match('^(%w+)%s*=%s*(.+)$')
            end
            -- Only store keys we're interested in
            if k and v and keys[k] then
                info[k] = v
            end
        end
        f:close()
        return info
    end

    -- Try modern /etc/os-release first (contains NAME and VERSION)
    local os_info =
        parse_release_file('/etc/os-release', { NAME = true, VERSION = true })
    if os_info and os_info.NAME then
        if os_info.VERSION then
            return os_info.NAME .. ' ' .. os_info.VERSION
        else
            return os_info.NAME
        end
    end

    -- Fall back to legacy /etc/lsb-release (contains DISTRIB_* keys)
    local lsb_info = parse_release_file('/etc/lsb-release', {
        DISTRIB_DESCRIPTION = true,
        DISTRIB_ID = true,
        DISTRIB_RELEASE = true,
    })
    if lsb_info then
        if lsb_info.DISTRIB_DESCRIPTION then
            return lsb_info.DISTRIB_DESCRIPTION
        elseif lsb_info.DISTRIB_ID and lsb_info.DISTRIB_RELEASE then
            return lsb_info.DISTRIB_ID .. ' ' .. lsb_info.DISTRIB_RELEASE
        elseif lsb_info.DISTRIB_ID then
            return lsb_info.DISTRIB_ID
        end
    end

    -- Final fallback if neither file provides useful info
    return 'Linux (unknown version)'
end

-- Detect desktop environment or window manager
-- Checks environment variables to identify running DE/WM
-- Prioritizes Hyprland detection, then XDG standards, then Wayland
function M.desktop_environment_info()
    -- Standard environment variables for desktop detection
    local xdg_desktop = os.getenv('XDG_CURRENT_DESKTOP') -- Current desktop name
    local xdg_session = os.getenv('XDG_SESSION_DESKTOP') -- Session desktop name
    local wayland_session = os.getenv('WAYLAND_DISPLAY') -- Wayland session indicator
    local hyprland_env = os.getenv('HYPRLAND_INSTANCE_SIGNATURE') -- Hyprland-specific env var

    -- Hyprland detection: check both specific env var and desktop name
    if hyprland_env or (xdg_desktop and xdg_desktop:lower():find('hypr')) then
        return 'Hyprland'
    elseif xdg_desktop then
        -- Use current desktop if available
        return xdg_desktop
    elseif xdg_session then
        -- Fall back to session desktop
        return xdg_session
    elseif wayland_session then
        -- Generic Wayland if no specific DE detected
        return 'Wayland (unknown compositor)'
    else
        -- Unknown if none of the above work
        return 'Unknown DE/WM'
    end
end

-- Copy current file path to system clipboard with visual feedback
-- Shows filename, path, cursor position, and total lines in notification
-- Formats notification differently based on path length for readability
function M.copy_file_path()
    -- Get relative path from home directory (e.g., "Documents/file.txt")
    local path = vim.fn.expand('%:~:.')

    -- Copy to system clipboard (register "+")
    vim.fn.setreg('+', path)

    -- Gather file info for notification
    local filename = vim.fn.expand('%:t') -- Just filename
    local cursor = vim.fn.line('.') .. ':' .. vim.fn.col('.') -- Current position (line:col)
    local lines = vim.fn.line('$') -- Total lines in file

    -- Refresh UI to ensure clean state for notification
    M.ui.refresh_ui()

    -- Show notification with different formatting based on path length
    -- Long paths get newline separator, short paths get inline format
    if #path > 50 then
        vim.notify(
            '"'
                .. path
                .. '"'
                .. '\n'
                .. cursor
                .. ' '
                .. lines
                .. ' lines\n'
                .. 'Filepath copied to the clipboard.',
            vim.log.levels.INFO,
            {
                title = filename,
            }
        )
    else
        vim.notify(
            '"'
                .. path
                .. '"'
                .. ' @ '
                .. cursor
                .. ' '
                .. lines
                .. ' lines\n'
                .. 'Filepath copied to the clipboard.',
            vim.log.levels.INFO,
            {
                title = filename,
            }
        )
    end
end
return M
