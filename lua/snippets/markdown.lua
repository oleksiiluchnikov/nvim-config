local luasnip = require('luasnip')
local fmt = require('luasnip.extras.fmt').fmt
local ft = 'markdown'

local s = luasnip.snippet
local i = luasnip.i
local c = luasnip.choice_node
local t = luasnip.text_node

local function get_title()
    -- find the first line that starts with '#\s' and use that as the title
    local title = ''
    for _, line in ipairs(vim.api.nvim_buf_get_lines(0, 0, -1, false)) do
        if line:match('^#+%s') then
            title = line
            break
        end
    end
    return title
end

luasnip.add_snippets(ft, {
    s(
        { trig = 'created', dscr = 'Created date' },
        fmt(
            [[
        created: {}
        ]],
            {
                i(1, os.date('%Y%m%d%H%M%S')),
            }
        )
    ),
    s(
        { trig = 'title', dscr = 'Title' },
        fmt(
            [[
        title: {}
        ]],
            {
                i(1, get_title()),
            }
        )
    ),
    s(
        { trig = 'frontmatter', dscr = 'Document frontmatter' },
        fmt(
            [[
      ---
      tags: {}
      ---

    ]],
            {
                i(1, 'value'),
            }
        )
    ),
    s(
        { trig = 'type', dscr = 'Type' },
        fmt(
            [[
        type: {}
        ]],
            {
                i(1, 'value'),
            }
        )
    ),
    s(
        { trig = 'status', dscr = 'Status' },
        fmt(
            [[
        status: {}
        ]],
            {
                -- i(1, "value"),
                c(1, {
                    t('TODO'),
                    t('IN-PROGRESS'),
                    t('DONE'),
                    t('IN-REVIEW'),
                    t('ARCHIVED'),
                    t('ON-HOLD'),
                    t('DEPRECATED'),
                    t('ACTIVE'),
                }),
            }
        )
    ),
    s('prompt', {
        t('---'),
        t({ '', 'name: ' }),
        i(1, 'Prompt Name'), -- [2, 4]
        t({ '', 'description: ' }),
        i(2, 'Description'), -- [2]
        t({ '', 'interaction: ' }),
        i(3, 'chat'), -- [2]
        t({ '', 'model: ' }),
        i(4, 'google/gemini-3-pro'), -- [3]
        t({ '', 'creativity: ' }),
        i(5, 'medium'), -- [4]
        t({ '', 'opts:' }), -- [1, 2]
        t({ '', '  alias: ' }),
        i(6, 'cmd'), -- [3]
        t({ '', '  is_slash_cmd: ' }),
        i(7, 'true'), -- [3]
        t({ '', '  auto_submit: ' }),
        i(8, 'false'), -- [3]
        t({ '', '---', '', '' }),
        t('## user'), -- [5]
        t({ '', '', '### Instructions & Use Cases', '' }),
        t('- Scenario: '),
        i(9, 'Use for [case]'),
        t({ '', '- Notes: ' }),
        i(10, 'instructions'),
        t({ '', '', '---', '', '' }),
        t('### Compiled Prompt'),
        t({ '', '', '![[' }),
        i(11, 'Role'),
        t(']] ![['),
        i(12, 'Constraint'),
        t({ ']]', '', '' }), -- [6]
        t('Subject: ${context.code}'), -- [7]
        i(0),
    }),
})
