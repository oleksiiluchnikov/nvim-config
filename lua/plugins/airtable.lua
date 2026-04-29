-- ╭──────────────────────────────────────────────────────────────────╮
-- │                       airtable.nvim                             │
-- ╰──────────────────────────────────────────────────────────────────╯
--
-- Recipes (Lua API)
-- ─────────────────
-- All recipes target base appmj8BtVyn4iyqm2 / table tblswsocgnqxmHXq0 ("Tasks").
--
-- Kanban by Time Context:
--   require("airtable.kanban").open_for_table("appmj8BtVyn4iyqm2", "tblswsocgnqxmHXq0", "📝 Tasks", nil, {
--     group_field = "Time Context",
--     display_fields = { "Action", "Category", "📅 Due Date" },
--     card_mode = true,
--   })
--
-- Kanban by Status:
--   require("airtable.kanban").open_for_table("appmj8BtVyn4iyqm2", "tblswsocgnqxmHXq0", "📝 Tasks", nil, {
--     group_field = "🚦Status",
--     display_fields = { "Action", "Category", "📅 Due Date" },
--   })
--
-- Kanban by Category:
--   require("airtable.kanban").open_for_table("appmj8BtVyn4iyqm2", "tblswsocgnqxmHXq0", "📝 Tasks", nil, {
--     group_field = "Category",
--     display_fields = { "Action", "Time Context", "📅 Due Date" },
--   })
--
-- Live editor (all fields):
--   require("airtable.editor").open_for_table("appmj8BtVyn4iyqm2", "tblswsocgnqxmHXq0", "📝 Tasks")
--
-- Live editor (selected fields):
--   require("airtable.editor").open_for_table("appmj8BtVyn4iyqm2", "tblswsocgnqxmHXq0", "📝 Tasks", nil, {
--     display_fields = { "Action", "Category", "🚦Status", "📅 Due Date", "Persons" },
--   })
--
-- Live editor (with view + sort):
--   require("airtable.editor").open_for_table("appmj8BtVyn4iyqm2", "tblswsocgnqxmHXq0", "📝 Tasks", nil, {
--     view = "Grid view",
--     sort = { { field = "📅 Due Date", direction = "asc" } },
--   })
--
-- :Airtable commands (equivalent CLI)
-- ────────────────────────────────────
--   :Airtable board group_field=Category display_fields=Action,Time\ Context
--   :Airtable edit view=Grid\ view sort=📅\ Due\ Date:asc
--   :Airtable record view=Grid\ view
--   :Airtable pick
--   :Airtable schema
--   :Airtable sync
--   :Airtable cache clear
--   :Airtable analytics
--   :Airtable timeline

local BASE = 'appmj8BtVyn4iyqm2'
local TABLE = 'tblswsocgnqxmHXq0'
local TABLE_NAME = 'do/📝 Tasks'
local CONTENT_TABLE = 'tbl8RSSQMkdqSIGfK'
local CONTENT_TABLE_NAME = 'create/🎨 Content'
-- Status record IDs from meta/🚦Statuses table
local STATUS_TODO     = 'recZMm68CI7BLT77C'  -- ⚡️ Todo
local STATUS_DONE     = 'rec6hMQUkRWCBclHz'  -- ✅ Done
-- "Today's Focus Grid" view
local VIEW_TODAY      = 'viwm0RIFursvDRzQX'
-- Writable date field for Tasks (📅 Due Date is a formula — read-only)
local TASKS_DATE_FIELD = '🛫 Start Date/Available At'

return {
    {
        'oleksiiluchnikov/airtable.nvim',
        dir = '~/projects/airtable.nvim',
        lazy = false,
        dependencies = {
            'nvim-lua/plenary.nvim',
            'nvim-telescope/telescope.nvim',
            'oleksiiluchnikov/teolog.nvim',
        },
        cmd = {
            'Airtable',
            'AirtableBasePicker',
            'AirtableTablePicker',
            'AirtableRecordPicker',
            'AirtableCommandPalette',
            'AirtableAnalytics',
        },
        keys = {
            {
                '<leader>aT',
                '<cmd>Airtable tasks<cr>',
                desc = "Airtable: Tasks picker (today's focus)",
            },
            -- Recipes
            {
                '<leader>a<CR>',
                function() require('airtable.pickers.recipe').open() end,
                desc = 'Airtable: Recipe picker',
            },
            -- Pickers
            {
                '<leader>ak',
                '<cmd>AirtableCommandPalette<cr>',
                desc = 'Airtable: Command Palette',
            },
            {
                '<leader>ab',
                '<cmd>AirtableBasePicker<cr>',
                desc = 'Airtable: Browse Bases',
            },
            {
                '<leader>at',
                '<cmd>AirtableTablePicker<cr>',
                desc = 'Airtable: Browse Tables',
            },
            {
                '<leader>ar',
                '<cmd>AirtableRecordPicker<cr>',
                desc = 'Airtable: Browse Records',
            },
            -- Direct views for Tasks table
            {
                '<leader>ae',
                function()
                    require('airtable.editor').open_for_table(BASE, TABLE, TABLE_NAME, nil, {
                        display_fields = { 'Action', 'Category', '🚦Status', '📅 Due Date', 'Persons' },
                    })
                end,
                desc = 'Airtable: Tasks editor',
            },
            {
                '<leader>aK',
                function()
                    require('airtable.kanban').open_for_table(BASE, TABLE, TABLE_NAME, nil, {
                        group_field = 'Time Context',
                        display_fields = { 'Action', 'Category', '📅 Due Date' },
                        card_mode = true,
                    })
                end,
                desc = 'Airtable: Tasks kanban (Time Context)',
            },
            {
                '<leader>as',
                function()
                    require('airtable.kanban').open_for_table(BASE, TABLE, TABLE_NAME, nil, {
                        group_field = '🚦Status',
                        display_fields = { 'Action', 'Category', '📅 Due Date' },
                    })
                end,
                desc = 'Airtable: Tasks kanban (Status)',
            },
            {
                '<leader>ac',
                function()
                    require('airtable.kanban').open_for_table(BASE, TABLE, TABLE_NAME, nil, {
                        group_field = 'Category',
                        display_fields = { 'Action', 'Time Context', '📅 Due Date' },
                    })
                end,
                desc = 'Airtable: Tasks kanban (Category)',
            },
            -- Calendar views
            {
                '<leader>aC',
                function()
                    require('airtable.views.calendar').open_for_table(BASE, TABLE, TABLE_NAME, nil, {
                        date_field = TASKS_DATE_FIELD,
                        display_fields = { 'Action', 'Category' },
                    })
                end,
                desc = 'Airtable: Tasks calendar',
            },
            -- Content table
            {
                '<leader>a1',
                function()
                    require('airtable.views.calendar').open_for_table(BASE, CONTENT_TABLE, CONTENT_TABLE_NAME, nil, {
                        display_fields = { 'Title', 'Status' },
                    })
                end,
                desc = 'Airtable: Content calendar',
            },
            {
                '<leader>a2',
                function()
                    require('airtable.editor').open_for_table(BASE, CONTENT_TABLE, CONTENT_TABLE_NAME, nil, {
                        display_fields = { 'Title', 'Status', 'Type', 'Garden' },
                    })
                end,
                desc = 'Airtable: Content editor',
            },
            {
                '<leader>a3',
                function()
                    require('airtable.kanban').open_for_table(BASE, CONTENT_TABLE, CONTENT_TABLE_NAME, nil, {
                        group_field = 'Status',
                        display_fields = { 'Title', 'Type', 'Garden' },
                        card_mode = true,
                    })
                end,
                desc = 'Airtable: Content kanban (Status)',
            },
            {
                '<leader>aa',
                '<cmd>AirtableAnalytics<cr>',
                desc = 'Airtable: Analytics Dashboard',
            },
        },
        config = function()
            require('airtable').setup({
                api_key = vim.env.AIRTABLE_API_KEY,
                default_base = vim.env.AIRTABLE_BASE_ID,

                confirm = {
                    enabled = false,
                },

                http = {
                    timeout = 30000,
                },
                ui = {
                    default_record_fields = { 'Name', 'Status', 'ID' },
                },
                cache = {
                    ttl = 3600,
                    max_size_mb = 50,
                },
                sync = {
                    show_progress = false,
                    auto_sync_on_startup = false,
                },

                shortcuts = {
                    tasks = {
                        base_id        = BASE,
                        table_id       = TABLE,
                        table_name     = TABLE_NAME,
                        view_id        = VIEW_TODAY,
                        action_field   = 'Action',
                        status_field   = '🚦Status',
                        done_status_id = STATUS_DONE,
                        todo_status_id = STATUS_TODO,
                        -- Fields merged into every new record created with `a`.
                        -- Use this to satisfy view/formula filters so new tasks
                        -- appear in the picker immediately after creation.
                        -- Example: create_defaults = { ['Time Context'] = 'Today' }
                        create_defaults = {},
                    },
                },

                recipes = {
                    {
                        name = 'Active by Time Context',
                        icon = '󰕴',
                        view = 'kanban',
                        base_id = BASE,
                        table_id = TABLE,
                        table_name = TABLE_NAME,
                        opts = {
                            group_field = 'Time Context',
                            display_fields = { 'Action', 'Category', '📅 Due Date' },
                            card_mode = true,
                            filter = "AND({🚦Status} != 'Done', {🚦Status} != 'Archived', {🚦Status} != 'Backlog')",
                        },
                    },
                    {
                        name = 'Active by Status',
                        icon = '🚦',
                        view = 'kanban',
                        base_id = BASE,
                        table_id = TABLE,
                        table_name = TABLE_NAME,
                        opts = {
                            group_field = '🚦Status',
                            display_fields = { 'Action', 'Category', '📅 Due Date' },
                            filter = "AND({🚦Status} != 'Done', {🚦Status} != 'Archived', {🚦Status} != 'Backlog')",
                        },
                    },
                    {
                        name = 'Active by Category',
                        icon = '󰷏',
                        view = 'kanban',
                        base_id = BASE,
                        table_id = TABLE,
                        table_name = TABLE_NAME,
                        opts = {
                            group_field = 'Category',
                            display_fields = { 'Action', 'Time Context', '📅 Due Date' },
                            filter = "AND({🚦Status} != 'Done', {🚦Status} != 'Archived', {🚦Status} != 'Backlog')",
                        },
                    },
                    -- ── Unfiltered (all records) ──
                    {
                        name = 'All tasks by Status',
                        icon = '🚦',
                        view = 'kanban',
                        base_id = BASE,
                        table_id = TABLE,
                        table_name = TABLE_NAME,
                        opts = {
                            group_field = '🚦Status',
                            display_fields = { 'Action', 'Category', '📅 Due Date' },
                        },
                    },
                    {
                        name = 'Tasks editor (key fields)',
                        icon = '',
                        view = 'editor',
                        base_id = BASE,
                        table_id = TABLE,
                        table_name = TABLE_NAME,
                        opts = {
                            display_fields = { 'Action', 'Category', '🚦Status', '📅 Due Date', 'Persons' },
                        },
                    },
                    {
                        name = 'Tasks editor (all fields)',
                        icon = '',
                        view = 'editor',
                        base_id = BASE,
                        table_id = TABLE,
                        table_name = TABLE_NAME,
                    },
                    {
                        name = 'Tasks calendar',
                        icon = '📅',
                        view = 'calendar',
                        base_id = BASE,
                        table_id = TABLE,
                        table_name = TABLE_NAME,
                        opts = {
                            date_field = TASKS_DATE_FIELD,
                            display_fields = { 'Action', 'Category' },
                        },
                    },
                    -- ── Content ──
                    {
                        name = 'Content calendar',
                        icon = '📅',
                        view = 'calendar',
                        base_id = BASE,
                        table_id = CONTENT_TABLE,
                        table_name = CONTENT_TABLE_NAME,
                        opts = {
                            display_fields = { 'Title', 'Status' },
                        },
                    },
                    {
                        name = 'Content by Status',
                        icon = '🎨',
                        view = 'kanban',
                        base_id = BASE,
                        table_id = CONTENT_TABLE,
                        table_name = CONTENT_TABLE_NAME,
                        opts = {
                            group_field = 'Status',
                            display_fields = { 'Title', 'Type', 'Garden' },
                            card_mode = true,
                        },
                    },
                    {
                        name = 'Content editor',
                        icon = '',
                        view = 'editor',
                        base_id = BASE,
                        table_id = CONTENT_TABLE,
                        table_name = CONTENT_TABLE_NAME,
                        opts = {
                            display_fields = { 'Title', 'Status', 'Type', 'Garden' },
                        },
                    },
                },
            })
        end,
    },
}
