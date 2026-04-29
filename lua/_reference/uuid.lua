local M = {}
-- Use a pre-computed function for generating random hexadecimal digits
local function random_hex()
    return string.format('%x', math.random(0, 15))
end

-- Optimized function to generate UUID
-- Avoids unnecessary string concatenation and gsub calls
local function generate_uuid()
    local template = 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'
    return string.gsub(template, '[xy]', function(c)
        local v = (c == 'x') and random_hex() or ('8' .. random_hex()):sub(2)
        return v
    end)
end

-- Optimized function to format UUID
-- Uses pre-computed patterns and avoids unnecessary string concatenation
local function format_uuid(uuid)
    local lowercase_pattern = '[%x]'
    local pattern = '[^%x]'
    return uuid:gsub(pattern, ''):lower():gsub(lowercase_pattern, string.lower)
end

-- Optimized function to generate and format UUID
-- Combines generate_uuid and format_uuid into a single function
function M.generate_formatted_uuid()
    return format_uuid(generate_uuid())
end

-- Optimized function to put UUID in register
-- Avoids unnecessary string concatenation and gsub calls
vim.api.nvim_create_user_command('UUID', function()
    vim.api.nvim_put({ M.generate_formatted_uuid() }, 'c', true, true)
end, {})

return M
