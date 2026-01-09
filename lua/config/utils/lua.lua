local M
--- Converts lines of text based on a pattern and format
--- @param lines table -- A table containing lines of text
--- @param from_pattern string -- The pattern to match against each line
--- @param to_format string -- The format string to use for converting matched lines
--- @example
--- ```lua
--- local lines = {"foo(arg1, arg2)", "bar(arg3)", "baz(arg4, arg5)"}
--- local pattern = "(%w+)%((.+)%)"
--- local format = "%s(%2)"
---
--- local converted_lines = convert_lines(lines, pattern, format)
---
--- -- Asserts
--- assert(#converted_lines == 3)
--- assert(converted_lines[1] == "foo(arg1, arg2)")
--- assert(converted_lines[2] == "bar(arg3)")
--- assert(converted_lines[3] == "baz(arg4, arg5)")
--- ```
--- @return table -- A new table containing the converted lines
local function convert_lines(lines, from_pattern, to_format)
    local new_lines = {} -- Table to store the converted lines

    for _, line in ipairs(lines) do
        if string.match(line, from_pattern) then
            local func_name, args = string.match(line, from_pattern)
            local new_line = string.format(to_format, func_name, args)
            table.insert(new_lines, new_line)
        else
            table.insert(new_lines, line)
        end
    end

    -- Return the new table containing the converted lines
    return new_lines
end
---Entry point for converting a Lua function
---@return nil
function M.toggle_function()
    local buf = vim.api.nvim_get_current_buf() -- Get the current buffer
    local lnum = vim.fn.line('.') -- Get the current line number
    local line = vim.api.nvim_buf_get_lines(buf, lnum - 1, lnum, false)[1] -- Get the current line

    -- Precompile patterns for better performance
    local function_pattern = '^%s*function%s*([^%(]+)%('
    local public_pattern = '^%s*(%w+)%.'
    local local_pattern = '^%s*function%s*(%w+)%.'

    -- Use string.find instead of string.match for better performance
    local function_name = line:find(function_pattern)
    if function_name then
        local module_name
        if line:find(public_pattern) then
            -- Capture the module name using string.match
            module_name = line:match(public_pattern)
            M.function_from_public_to_local(buf, lnum - 1, lnum, module_name)
        elseif line:find(local_pattern) then
            -- Capture the module name using string.match
            module_name = line:match(local_pattern)
            M.function_from_local_to_public(buf, lnum - 1, lnum, module_name)
        end
    else
        -- Use early return to avoid unnecessary computation
        vim.notify(
            'Cursor is not on a function definition',
            vim.log.levels.WARN
        )
        return
    end
end

--- Get the source of a function that is passed in.
--- @param func function
--- @return table|nil
function M.get_function_source(func)
    ---@type debuginfo
    local info = debug.getinfo(func, 'S')
    if not info.source or info.source:sub(1, 1) ~= '@' then
        return nil
    end

    local path = info.source:sub(2)

    ---@type file*?
    local f, err = assert(io.open(path, 'rb'))
    if not f then
        vim.notify(err, vim.log.levels.ERROR, { title = 'ERROR' })
        return nil
    end
    local first_line
    local lnum = 0
    for line in f:lines() do
        lnum = lnum + 1
        if lnum == info.linedefined then
            first_line = line
            break
        end
    end
    f:close()

    if not first_line then
        return nil
    end

    local tbl = {
        first_line = first_line,
        path = path,
        func_name = first_line:match('function%s+(%w+)') or first_line:match(
            'local%s+(%w+)'
        ) or first_line:match('(%w+)%s*='),
        path_to_parent = path:match('(.*/)'),
    }
    return tbl
end
--- Example usage
--- ```

--- Converts local module functions to public functions
--- @param buf number Buffer handle
--- @param start_line integer Start line
--- @param end_line integer End line
--- @param module_name string Module name
--- @return string[] Modified lines
function M.function_from_local_to_public(buf, start_line, end_line, module_name)
    --- @type string[]
    local lines = vim.api.nvim_buf_get_lines(buf, start_line, end_line, false)

    local pattern = '^function ' .. module_name .. '%.([a-zA-Z0-9_]+)%((.*)%)$'
    local to_format = module_name .. '.%s = function(%s)'

    --- @type string[]
    local new_lines = convert_lines(lines, pattern, to_format)

    vim.api.nvim_buf_set_lines(buf, start_line, end_line, false, new_lines)

    --- @type string[]
    return new_lines
end

function M.function_from_public_to_local(buf, start_line, end_line, module_name)
    local lnum = vim.api.nvim_win_get_cursor(0)[1]
    local line = vim.api.nvim_get_current_line()

    if is_function_definition(line) then
        local new_lines = convert_function(buf, lnum, line, module_name)
        vim.api.nvim_buf_set_lines(
            buf,
            start_line - 1,
            end_line,
            false,
            new_lines
        )
    else
        vim.notify(
            'Cursor is not on a function definition',
            vim.log.levels.WARN
        )

        convert_function(buf, lnum, line)
    end
end

--- @alias LuaVersion string
--- |> 'LuaJIT'
--- |> 'Lua 5.1'
--- |> 'Lua 5.2'
--- |> 'Lua 5.3'
--- |> 'Lua 5.4'

--- Get the lua version of the current buffer
---
--- @return LuaVersion
--- ```lua
--- local lua_version = require('config.utils').get_lua_version()
--- assert(lua_version == 'LuaJIT' or lua_version == 'Lua 5.1')
--- ```
function M.get_version()
    local buffer_path = tostring(vim.fn.expand('%:p:h'))
    local nvim_path = tostring(vim.fn.stdpath('config'))
    local is_neovim = string.find(buffer_path, nvim_path) and true or false
    local is_hammerspoon = string.find(buffer_path, 'hammerspoon') and true
        or false

    ---@type LuaVersion
    local lua_version

    if is_neovim then
        lua_version = 'LuaJIT'
    elseif is_hammerspoon then
        local lua_version_str =
            vim.fn.system('hs -c _VERSION'):gsub('[\n\r]', '')
        if lua_version_str:match('^error') then
            vim.notify(lua_version_str, vim.log.levels.ERROR, {
                title = 'Neovim',
            })
        end
        ---@diagnostic disable-next-line: cast-local-type
        lua_version = lua_version_str
    else
        lua_version = 'LuaJIT'
    end

    return lua_version
end
function M.write_then_source()
    vim.cmd('write')
    local filetype = vim.bo.filetype
    if filetype == 'lua' then
        local current_path = vim.fn.expand('%:p')
        if type(current_path) ~= 'string' then
            return
        end
        if current_path:find('config/hammerspoon') ~= nil then
            vim.execute('hs -c "hs.reload()"')
        else
            vim.cmd('luafile %')
        end
        vim.cmd('source %')
    end
end
return M
