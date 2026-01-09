---@module 'snippets.ft.all'
---@description Global snippets available in all filetypes

local u = require('snippets.utils')
local s, t, i, f, c = u.s, u.t, u.i, u.f, u.c
local fmt = u.fmt

return {
    -- Quick trigger test
    s('trig', {
        t('LuaSnip is loaded and working!'),
    }),

    -- Date and time snippets
    s({ trig = 'date', name = 'Date', dscr = 'Insert current date' }, {
        u.date_node('%Y-%m-%d'),
    }),

    s({
        trig = 'ddate',
        name = 'Date (verbose)',
        dscr = 'Insert date with day name',
    }, {
        u.date_node('%Y-%m-%d %A'),
    }),

    s({ trig = 'time', name = 'Time', dscr = 'Insert current time' }, {
        u.time_node('%H:%M:%S'),
    }),

    s({
        trig = 'datetime',
        name = 'DateTime',
        dscr = 'Insert current date and time',
    }, {
        t(u.get_iso_datetime()),
    }),

    s({ trig = 'now', name = 'Timestamp', dscr = 'ISO 8601 timestamp' }, {
        t(u.get_iso_datetime()),
    }),

    -- File information snippets
    s({
        trig = 'filename',
        name = 'Filename',
        dscr = 'Insert current filename',
    }, {
        u.filename_node(false),
    }),

    s({
        trig = 'filepath',
        name = 'Filepath',
        dscr = 'Insert relative filepath',
    }, {
        f(function()
            return u.get_relative_path()
        end),
    }),

    -- Author and metadata
    s({ trig = 'author', name = 'Author', dscr = 'Insert username' }, {
        u.username_node(),
    }),

    s({
        trig = 'todo',
        name = 'TODO Comment',
        dscr = 'TODO with author and date',
    }, {
        u.todo_comment(),
    }),

    -- Common abbreviations and fixes
    s({
        trig = 'lorem',
        name = 'Lorem Ipsum',
        dscr = 'Lorem ipsum placeholder text',
    }, {
        t(
            'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.'
        ),
    }),

    -- Email and contact
    s(
        { trig = 'email', name = 'Email Template', dscr = 'Email template' },
        fmt(
            [[
Hi {},

{}

Best regards,
{}
]],
            {
                i(1, 'Name'),
                i(2, 'Message'),
                u.username_node(),
            }
        )
    ),

    -- UUID generator (simple version - you might want a proper UUID library)
    s({ trig = 'uuid', name = 'UUID', dscr = 'Generate a simple unique ID' }, {
        f(function()
            local template = 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'
            return string.gsub(template, '[xy]', function(c)
                local v = (c == 'x') and math.random(0, 0xf)
                    or math.random(8, 0xb)
                return string.format('%x', v)
            end)
        end),
    }),

    -- Shebang for scripts
    s({ trig = 'shebang', name = 'Shebang', dscr = 'Script shebang line' }, {
        t('#!/usr/bin/env '),
        c(1, {
            t('bash'),
            t('python3'),
            t('node'),
            t('ruby'),
            t('perl'),
            i(nil, 'interpreter'),
        }),
    }),

    -- Box comment
    s(
        { trig = 'box', name = 'Box Comment', dscr = 'Create a boxed comment' },
        fmt(
            [[
{}
{} {} {}
{}
]],
            {
                f(function()
                    return u.get_comment_string() .. ' ' .. string.rep('=', 76)
                end),
                f(function()
                    return u.get_comment_string()
                end),
                i(1, 'Section Title'),
                f(function()
                    return u.get_comment_string()
                end),
                f(function()
                    return u.get_comment_string() .. ' ' .. string.rep('=', 76)
                end),
            }
        )
    ),
}
