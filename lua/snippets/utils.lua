---@module 'snippets.utils'
---@description Utility functions and common patterns for LuaSnip snippets
---@author Your Name
---@license MIT

local ls = require('luasnip')
local fmt = require('luasnip.extras.fmt').fmt
local rep = require('luasnip.extras').rep

-- Core LuaSnip modules
local s = ls.snippet
local sn = ls.snippet_node
local t = ls.text_node
local i = ls.insert_node
local f = ls.function_node
local c = ls.choice_node
local d = ls.dynamic_node
local r = ls.restore_node
local l = require('luasnip.extras').lambda
local p = require('luasnip.extras').partial
local m = require('luasnip.extras').match
local n = require('luasnip.extras').nonempty
local dl = require('luasnip.extras').dynamic_lambda
local fmta = require('luasnip.extras.fmt').fmta
local types = require('luasnip.util.types')
local conds = require('luasnip.extras.conditions')
local conds_expand = require('luasnip.extras.conditions.expand')

local M = {}

-- Export commonly used functions for snippets
M.s = s
M.sn = sn
M.t = t
M.i = i
M.f = f
M.c = c
M.d = d
M.r = r
M.fmt = fmt
M.fmta = fmta
M.rep = rep
M.l = l
M.p = p
M.m = m
M.n = n
M.dl = dl
M.conds = conds
M.conds_expand = conds_expand
M.types = types
M.events = require('luasnip.util.events')
M.ai = require('luasnip.nodes.absolute_indexer')
M.postfix = require('luasnip.extras.postfix').postfix

-- ============================================================================
-- Utility Functions
-- ============================================================================

---Create a function node that copies another insert node's text
---@param index number The insert node index to copy from
---@return table Function node
function M.same(index)
    return f(function(args)
        return args[1]
    end, { index })
end

---Get the current date in a specific format
---@param format? string strftime format string (default: '%Y-%m-%d')
---@return string Formatted date
function M.get_date(format)
    return os.date(format or '%Y-%m-%d')
end

---Get the current time in a specific format
---@param format? string strftime format string (default: '%H:%M:%S')
---@return string Formatted time
function M.get_time(format)
    return os.date(format or '%H:%M:%S')
end

---Get the current datetime in ISO 8601 format
---@return string ISO 8601 datetime
function M.get_iso_datetime()
    return os.date('%Y-%m-%dT%H:%M:%S')
end

---Create a date node (function node that returns current date)
---@param format? string strftime format string
---@return table Function node
function M.date_node(format)
    return f(function()
        return M.get_date(format)
    end)
end

---Create a time node (function node that returns current time)
---@param format? string strftime format string
---@return table Function node
function M.time_node(format)
    return f(function()
        return M.get_time(format)
    end)
end

---Get filename without extension
---@return string Filename without extension
function M.get_filename()
    return vim.fn.expand('%:t:r')
end

---Get filename with extension
---@return string Filename with extension
function M.get_filename_full()
    return vim.fn.expand('%:t')
end

---Get relative path from cwd
---@return string Relative path
function M.get_relative_path()
    return vim.fn.expand('%:.')
end

---Get absolute path
---@return string Absolute path
function M.get_absolute_path()
    return vim.fn.expand('%:p')
end

---Get the directory name of current file
---@return string Directory name
function M.get_dirname()
    return vim.fn.expand('%:p:h:t')
end

---Create a filename node (function node that returns filename)
---@param with_extension? boolean Include file extension (default: false)
---@return table Function node
function M.filename_node(with_extension)
    return f(function()
        if with_extension then
            return M.get_filename_full()
        else
            return M.get_filename()
        end
    end)
end

---Get visual selection text
---@return string[] Selected text lines
function M.get_visual_selection()
    local _, srow, scol = unpack(vim.fn.getpos('v'))
    local _, erow, ecol = unpack(vim.fn.getpos('.'))

    -- Handle reverse selection
    if srow > erow or (srow == erow and scol > ecol) then
        srow, erow = erow, srow
        scol, ecol = ecol, scol
    end

    local lines =
        vim.api.nvim_buf_get_text(0, srow - 1, scol - 1, erow - 1, ecol, {})
    return lines
end

---Create a choice node from a list of strings
---@param choices string[] List of choice strings
---@return table Choice node
function M.simple_choice(choices)
    local nodes = {}
    for _, choice in ipairs(choices) do
        table.insert(nodes, t(choice))
    end
    return c(1, nodes)
end

---Create a commented header/section divider
---@param comment_string string The comment string for the language (e.g., '//', '#', '--')
---@param width? number Width of the divider (default: 80)
---@return function Function that returns text nodes
function M.section_comment(comment_string, width)
    width = width or 80
    return function(title)
        local line = string.rep('=', width - #comment_string - 1)
        return {
            t({ comment_string .. ' ' .. line }),
            t({ '', comment_string .. ' ' .. title }),
            t({ '', comment_string .. ' ' .. line }),
        }
    end
end

---Transform text with a function (useful for case conversion, etc.)
---@param index number Insert node index to transform
---@param transform_fn function Function to transform the text
---@return table Function node
function M.transform(index, transform_fn)
    return f(function(args)
        return transform_fn(args[1][1])
    end, { index })
end

---Convert text to SCREAMING_SNAKE_CASE
---@param str string Input string
---@return string Converted string
function M.to_screaming_snake_case(str)
    return str:gsub('%s+', '_'):gsub('-', '_'):upper()
end

---Convert text to snake_case
---@param str string Input string
---@return string Converted string
function M.to_snake_case(str)
    return str:gsub('%s+', '_'):gsub('-', '_'):lower()
end

---Convert text to PascalCase
---@param str string Input string
---@return string Converted string
function M.to_pascal_case(str)
    return str:gsub('[_-](%w)', string.upper)
        :gsub('^%l', string.upper)
        :gsub('%s+', '')
end

---Convert text to camelCase
---@param str string Input string
---@return string Converted string
function M.to_camel_case(str)
    local result = M.to_pascal_case(str)
    return result:gsub('^%u', string.lower)
end

---Convert text to kebab-case
---@param str string Input string
---@return string Converted string
function M.to_kebab_case(str)
    return str:gsub('%s+', '-'):gsub('_', '-'):lower()
end

---Create a node that returns the username
---@return table Function node
function M.username_node()
    return f(function()
        return os.getenv('USER') or os.getenv('USERNAME') or 'user'
    end)
end

---Create a multiline comment block
---@param start_marker string Starting comment marker
---@param end_marker string Ending comment marker
---@param prefix? string Prefix for middle lines (default: ' * ')
---@return table Snippet nodes
function M.block_comment(start_marker, end_marker, prefix)
    prefix = prefix or ' * '
    return {
        t(start_marker),
        t({ '', prefix }),
        i(1, 'Description'),
        t({ '', end_marker }),
    }
end

---Get the comment string for the current filetype
---@return string Comment string
function M.get_comment_string()
    local cs = vim.bo.commentstring
    if cs == '' then
        return '//'
    end
    -- Extract the comment marker (remove the %s placeholder)
    return cs:gsub('%%s', ''):gsub('%s+$', '')
end

---Create a TODO comment with author and date
---@return table Snippet nodes
function M.todo_comment()
    local cs = M.get_comment_string()
    return {
        t(cs .. ' TODO('),
        M.username_node(),
        t(') ['),
        M.date_node('%Y-%m-%d'),
        t(']: '),
        i(1, 'Description'),
    }
end

---Wrap text in a surround pattern
---@param pattern string Pattern with $1 for the insert position
---@return function Function for use in snippets
function M.surround(pattern)
    return function(insert_index)
        local before, after = pattern:match('(.*)%$1(.*)')
        return {
            t(before),
            i(insert_index or 1),
            t(after),
        }
    end
end

-- ============================================================================
-- Advanced Snippet Helpers
-- ============================================================================

---Create a choice node with common boolean values
---@param default_index? number Default choice index (default: 1)
---@return table Choice node
function M.bool_choice(default_index)
    return c(default_index or 1, {
        t('true'),
        t('false'),
    })
end

---Create a choice node with common access modifiers
---@param lang? string Language ('js', 'java', 'cpp', etc.)
---@return table Choice node
function M.access_modifier_choice(lang)
    lang = lang or 'js'

    if lang == 'js' or lang == 'typescript' then
        return c(1, {
            t('public'),
            t('private'),
            t('protected'),
        })
    elseif lang == 'java' or lang == 'cpp' then
        return c(1, {
            t('public'),
            t('private'),
            t('protected'),
        })
    end

    return c(1, { t('') })
end

---Create dynamic import/require statement based on variable name
---@param lang string Language type ('js', 'ts', 'lua', 'python')
---@return table Dynamic node
function M.smart_import(lang)
    return d(2, function(args)
        local var_name = args[1][1]
        if var_name == '' then
            return sn(nil, { i(1) })
        end

        local module_name = M.to_kebab_case(var_name)

        if lang == 'lua' then
            return sn(nil, { t('require(\'' .. module_name .. '\')') })
        elseif lang == 'python' then
            return sn(nil, { t('import ' .. module_name) })
        elseif lang == 'js' or lang == 'ts' then
            return sn(nil, { t('require(\'' .. module_name .. '\')') })
        end

        return sn(nil, { i(1) })
    end, { 1 })
end

return M
