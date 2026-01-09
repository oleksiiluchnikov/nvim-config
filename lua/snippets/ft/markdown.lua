---@module 'snippets.ft.markdown'
---@description Markdown snippets for note-taking and documentation

local u = require('snippets.utils')
local s, t, i, f, c = u.s, u.t, u.i, u.f, u.c
local fmt = u.fmt

---Find the first heading in the buffer to use as title
---@return string First heading or empty string
local function get_first_heading()
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    for _, line in ipairs(lines) do
        local heading = line:match('^#+%s+(.+)$')
        if heading then
            return heading
        end
    end
    return ''
end

return {
    -- Frontmatter
    s(
        {
            trig = 'frontmatter',
            name = 'Frontmatter',
            dscr = 'YAML frontmatter block',
        },
        fmt(
            [[
---
title: {}
created: {}
tags: [{}]
---

{}
]],
            {
                f(get_first_heading),
                u.date_node('%Y%m%dT%H%M%S'),
                i(1, 'tag'),
                i(0),
            }
        )
    ),

    -- Frontmatter advanced
    s(
        {
            trig = 'front',
            name = 'Frontmatter (detailed)',
            dscr = 'Detailed frontmatter',
        },
        fmt(
            [[
---
title: {}
created: {}
updated: {}
tags: [{}]
type: {}
status: {}
---

{}
]],
            {
                i(1, f(get_first_heading)),
                u.date_node('%Y-%m-%d'),
                u.date_node('%Y-%m-%d'),
                i(2, 'tag'),
                c(3, {
                    t('note'),
                    t('document'),
                    t('article'),
                    t('project'),
                    i(nil, 'type'),
                }),
                c(4, {
                    t('draft'),
                    t('in-progress'),
                    t('complete'),
                    t('archived'),
                }),
                i(0),
            }
        )
    ),

    -- Headers
    s(
        { trig = 'h1', name = 'Heading 1', dscr = 'Level 1 heading' },
        fmt(
            [[
# {}
]],
            {
                i(1, 'Heading'),
            }
        )
    ),

    s(
        { trig = 'h2', name = 'Heading 2', dscr = 'Level 2 heading' },
        fmt(
            [[
## {}
]],
            {
                i(1, 'Heading'),
            }
        )
    ),

    s(
        { trig = 'h3', name = 'Heading 3', dscr = 'Level 3 heading' },
        fmt(
            [[
### {}
]],
            {
                i(1, 'Heading'),
            }
        )
    ),

    -- Links
    s(
        { trig = 'link', name = 'Link', dscr = 'Markdown link' },
        fmt(
            [[
[{}]({})
]],
            {
                i(1, 'text'),
                i(2, 'url'),
            }
        )
    ),

    s(
        { trig = 'img', name = 'Image', dscr = 'Markdown image' },
        fmt(
            [[
![{}]({})
]],
            {
                i(1, 'alt text'),
                i(2, 'image.png'),
            }
        )
    ),

    -- Code blocks
    s(
        { trig = 'code', name = 'Code Block', dscr = 'Fenced code block' },
        fmt(
            [[
```{}
{}
```
]],
            {
                i(1, 'language'),
                i(0, 'code'),
            }
        )
    ),

    s(
        { trig = 'bash', name = 'Bash Block', dscr = 'Bash code block' },
        fmt(
            [[
```bash
{}
```
]],
            {
                i(0),
            }
        )
    ),

    s(
        {
            trig = 'js',
            name = 'JavaScript Block',
            dscr = 'JavaScript code block',
        },
        fmt(
            [[
```javascript
{}
```
]],
            {
                i(0),
            }
        )
    ),

    s(
        { trig = 'py', name = 'Python Block', dscr = 'Python code block' },
        fmt(
            [[
```python
{}
```
]],
            {
                i(0),
            }
        )
    ),

    s(
        { trig = 'lua', name = 'Lua Block', dscr = 'Lua code block' },
        fmt(
            [[
```lua
{}
```
]],
            {
                i(0),
            }
        )
    ),

    -- Lists
    s(
        { trig = 'ul', name = 'Unordered List', dscr = 'Unordered list' },
        fmt(
            [[
- {}
]],
            {
                i(0),
            }
        )
    ),

    s(
        { trig = 'ol', name = 'Ordered List', dscr = 'Ordered list' },
        fmt(
            [[
1. {}
]],
            {
                i(0),
            }
        )
    ),

    s(
        { trig = 'task', name = 'Task List', dscr = 'Task list item' },
        fmt(
            [[
- [ ] {}
]],
            {
                i(0),
            }
        )
    ),

    s(
        { trig = 'taskdone', name = 'Task Done', dscr = 'Completed task item' },
        fmt(
            [[
- [x] {}
]],
            {
                i(0),
            }
        )
    ),

    -- Tables
    s(
        { trig = 'table', name = 'Table', dscr = 'Markdown table' },
        fmt(
            [[
| {} | {} |
| --- | --- |
| {} | {} |
]],
            {
                i(1, 'Header 1'),
                i(2, 'Header 2'),
                i(3, 'Cell 1'),
                i(4, 'Cell 2'),
            }
        )
    ),

    s(
        { trig = 'table3', name = 'Table (3 cols)', dscr = '3-column table' },
        fmt(
            [[
| {} | {} | {} |
| --- | --- | --- |
| {} | {} | {} |
]],
            {
                i(1, 'Header 1'),
                i(2, 'Header 2'),
                i(3, 'Header 3'),
                i(4, 'Cell 1'),
                i(5, 'Cell 2'),
                i(6, 'Cell 3'),
            }
        )
    ),

    -- Callouts/Admonitions
    s(
        { trig = 'note', name = 'Note Callout', dscr = 'Note admonition' },
        fmt(
            [[
> [!NOTE]
> {}
]],
            {
                i(0),
            }
        )
    ),

    s(
        {
            trig = 'warning',
            name = 'Warning Callout',
            dscr = 'Warning admonition',
        },
        fmt(
            [[
> [!WARNING]
> {}
]],
            {
                i(0),
            }
        )
    ),

    s(
        { trig = 'tip', name = 'Tip Callout', dscr = 'Tip admonition' },
        fmt(
            [[
> [!TIP]
> {}
]],
            {
                i(0),
            }
        )
    ),

    -- Quotes
    s(
        { trig = 'quote', name = 'Blockquote', dscr = 'Blockquote' },
        fmt(
            [[
> {}
]],
            {
                i(0),
            }
        )
    ),

    -- Metadata fields
    s(
        { trig = 'created', name = 'Created Date', dscr = 'Created date field' },
        fmt(
            [[
created: {}
]],
            {
                u.date_node('%Y-%m-%d'),
            }
        )
    ),

    s(
        { trig = 'title', name = 'Title', dscr = 'Title field' },
        fmt(
            [[
title: {}
]],
            {
                f(get_first_heading),
            }
        )
    ),

    s(
        { trig = 'type', name = 'Type', dscr = 'Type field' },
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
        { trig = 'status', name = 'Status', dscr = 'Status field' },
        fmt(
            [[
status: {}
]],
            {
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

    -- Horizontal rule
    s({ trig = 'hr', name = 'Horizontal Rule', dscr = 'Horizontal rule' }, {
        t('---'),
    }),

    -- Footnote
    s(
        { trig = 'footnote', name = 'Footnote', dscr = 'Footnote reference' },
        fmt(
            [[
[^{}]
]],
            {
                i(1, '1'),
            }
        )
    ),

    s(
        {
            trig = 'footdef',
            name = 'Footnote Definition',
            dscr = 'Footnote definition',
        },
        fmt(
            [[
[^{}]: {}
]],
            {
                i(1, '1'),
                i(2, 'Footnote text'),
            }
        )
    ),

    -- Details/Summary (HTML in Markdown)
    s(
        {
            trig = 'details',
            name = 'Details/Summary',
            dscr = 'Collapsible details block',
        },
        fmt(
            [[
<details>
<summary>{}</summary>

{}

</details>
]],
            {
                i(1, 'Summary'),
                i(0, 'Details'),
            }
        )
    ),

    -- Prompt Frontmatter
    s(
        {
            trig = 'prompt',
            name = 'Prompt Frontmatter',
            dscr = 'Prompt frontmatter',
        },
        fmt(
            [[
        ---
        name: {}
        description: {}
        interaction: {}
        model: {}
        creativity: {}
        opts:
          alias: {}
          is_slash_cmd: {}
          auto_submit: {}
        ---

        ## User

        ### Instructions & Use Cases

        - Scenario: {}
        - Notes: {}

        ---

        ### Compiled Prompt
        ]],
            {
                i(1, 'Prompt Name'),
                i(2, 'Description'),
                i(3, 'chat'),
                i(4, 'google/gemini-3-pro'),
                i(5, 'medium'),
                i(6, 'cmd'),
                i(7, 'true'),
                i(8, 'false'),
                i(9, 'Use for [case]'),
                i(10, 'instructions'),
                i(11, 'Role'),
                i(12, 'Constraint'),
            }
        )
    ),
}
