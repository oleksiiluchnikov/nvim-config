return {
    -- 1. Compat Layer
    {
        'saghen/blink.compat',
        version = '*',
        lazy = true,
        opts = { impersonate_nvim_cmp = true },
        config = function()
            local ok, cmp = pcall(require, 'cmp')
            if ok then
                cmp.ConfirmBehavior = { Insert = 'insert', Replace = 'replace' }
            end
        end,
    },

    -- 2. Local Source
    {
        lazy = true,
        dir = string.format('%s/projects/blink-dates.nvim', os.getenv('HOME')),
    },

    -- 3. Main Configuration
    {
        'saghen/blink.cmp',
        version = '0.*',
        dependencies = {
            'rafamadriz/friendly-snippets',
            'mikavilpas/blink-ripgrep.nvim',
            'giuxtaposition/blink-cmp-copilot',
            'Kaiser-Yang/blink-cmp-avante',
            'moyiz/blink-emoji.nvim',
            'folke/lazydev.nvim',
            'dmitmel/cmp-cmdline-history',
        },
        opts_extend = { 'sources.default' },

        --- @class blink.cmp.Config -- Placeholder added for LSP resolution
        opts = {
            enabled = function()
                return true
            end,

            -- ==========================================================
            -- CMDLINE CONFIGURATION
            -- ==========================================================
            cmdline = {
                enabled = true,
                sources = { 'cmdline', 'path', 'cmdline_history', 'buffer' },

                keymap = {
                    preset = 'cmdline',
                    ['<C-y>'] = { 'select_and_accept' },
                },

                -- We do NOT put 'draw' or 'documentation' here to avoid schema errors.
                -- The global 'completion' config handles the logic dynamically below.
                completion = {
                    menu = {
                        auto_show = true,
                    },
                },
            },

            -- ==========================================================
            -- MAIN EDITOR & DYNAMIC LOGIC
            -- ==========================================================
            completion = {
                keyword = { range = 'prefix' },
                trigger = {
                    prefetch_on_insert = true,
                    show_in_snippet = true,
                    show_on_keyword = true,
                    show_on_trigger_character = true,
                    show_on_blocked_trigger_characters = { ' ', '\n', '\t' },
                    show_on_accept_on_trigger_character = true,
                    show_on_insert_on_trigger_character = true,
                    show_on_x_blocked_trigger_characters = { '\'', '"', '(' },
                },
                list = {
                    max_items = 50,
                    selection = { preselect = true, auto_insert = false },
                    cycle = { from_bottom = true, from_top = true },
                },
                menu = {
                    enabled = true,
                    auto_show = true,
                    min_width = 80,
                    max_height = 12,
                    draw = {
                        align_to = 'label',
                        padding = 0,
                        gap = 1,
                        treesitter = {},

                        -- DYNAMIC COLUMNS FUNCTION
                        -- This handles both Editor and Cmdline layouts safely
                        columns = function(ctx)
                            -- Check current mode
                            local mode = vim.api.nvim_get_mode().mode

                            if mode == 'c' then
                                -- CMDLINE MODE LOGIC
                                local cmd_text = vim.fn.getcmdline()
                                -- Simple check: typing command (no space) vs args (has space)
                                local is_typing_command =
                                    not cmd_text:match('%s')

                                if is_typing_command then
                                    -- Simple: Label | Description
                                    return {
                                        { 'label', 'label_detail', gap = 1 },
                                        { 'label_description' },
                                    }
                                else
                                    -- Complex Args: Index | Icon | Label | Desc | Source
                                    return {
                                        { 'item_idx' },
                                        { 'kind_icon', 'kind', gap = 1 },
                                        { 'label', 'label_detail', gap = 1 },
                                        { 'label_description' },
                                        { 'source_name' },
                                    }
                                end
                            else
                                -- NORMAL EDITOR MODE LOGIC
                                return {
                                    { 'item_idx' },
                                    { 'kind_icon', 'kind', gap = 1 },
                                    { 'label', 'label_detail', gap = 1 },
                                    { 'label_description' },
                                    { 'source_name' },
                                }
                            end
                        end,

                        components = {
                            item_idx = {
                                ellipsis = false,
                                width = { max = 3 },
                                text = function(ctx)
                                    return ctx.idx == 10 and '0'
                                        or ctx.idx >= 10 and ' '
                                        or tostring(ctx.idx)
                                end,
                                highlight = 'BlinkCmpItemIdx',
                            },
                            kind_icon = {
                                ellipsis = false,
                                text = function(ctx)
                                    return ctx.kind_icon .. ctx.icon_gap
                                end,
                                highlight = function(ctx)
                                    return {
                                        {
                                            group = ctx.kind_hl,
                                            priority = 20000,
                                        },
                                    }
                                end,
                            },
                            kind = {
                                ellipsis = false,
                                width = { max = 12 },
                                text = function(ctx)
                                    return ctx.kind
                                end,
                                highlight = function(ctx)
                                    return ctx.kind_hl
                                end,
                            },
                            label = {
                                width = { fill = true, max = 60 },
                                text = function(ctx)
                                    return ctx.label
                                end,
                                highlight = function(ctx)
                                    local hl = {
                                        {
                                            0,
                                            #ctx.label,
                                            group = ctx.deprecated
                                                    and 'BlinkCmpLabelDeprecated'
                                                or 'BlinkCmpLabel',
                                        },
                                    }
                                    for _, idx in
                                        ipairs(ctx.label_matched_indices)
                                    do
                                        table.insert(hl, {
                                            idx,
                                            idx + 1,
                                            group = 'BlinkCmpLabelMatch',
                                        })
                                    end
                                    return hl
                                end,
                            },
                            label_detail = {
                                width = { max = 60 },
                                text = function(ctx)
                                    return ctx.label_detail or ''
                                end,
                                highlight = 'BlinkCmpLabelDetail',
                            },
                            label_description = {
                                width = { max = 80 },
                                text = function(ctx)
                                    return ctx.label_description
                                end,
                                highlight = 'BlinkCmpLabelDescription',
                            },
                            source_name = {
                                width = { max = 12 },
                                text = function(ctx)
                                    return '[' .. ctx.source_name .. ']'
                                end,
                                highlight = 'BlinkCmpSource',
                            },
                        },
                    },
                },
                documentation = {
                    auto_show = true,
                    auto_show_delay_ms = 10,
                    treesitter_highlighting = true,
                    window = { border = 'single' },
                },
                ghost_text = { enabled = false },
            },

            keymap = {
                preset = 'none',
                ['<C-space>'] = {
                    'show',
                    'show_documentation',
                    'hide_documentation',
                    desc = 'Blink: Toggle completion and docs',
                },
                ['<C-e>'] = { 'hide', 'fallback' },
                ['<C-y>'] = { 'select_and_accept', desc = 'Blink: Accept selection' },
                ['<C-p>'] = { 'select_prev', 'fallback', desc = 'Blink: Previous item' },
                ['<C-n>'] = { 'select_next', 'fallback', desc = 'Blink: Next item' },
                ['<C-b>'] = { 'scroll_documentation_up', 'fallback', desc = 'Blink: Scroll docs up' },
                ['<C-f>'] = { 'scroll_documentation_down', 'fallback', desc = 'Blink: Scroll docs down' },
                ['<Tab>'] = { 'snippet_forward', 'fallback', desc = 'Blink: Snippet forward' },
                ['<S-Tab>'] = { 'snippet_backward', 'fallback', desc = 'Blink: Snippet backward' },
                ['<A-1>'] = {
                    function(cmp)
                        cmp.accept({ index = 1 })
                    end,
                    desc = 'Blink: Accept item 1',
                },
                ['<A-2>'] = {
                    function(cmp)
                        cmp.accept({ index = 2 })
                    end,
                    desc = 'Blink: Accept item 2',
                },
                ['<A-3>'] = {
                    function(cmp)
                        cmp.accept({ index = 3 })
                    end,
                    desc = 'Blink: Accept item 3',
                },
                ['<A-4>'] = {
                    function(cmp)
                        cmp.accept({ index = 4 })
                    end,
                    desc = 'Blink: Accept item 4',
                },
                ['<A-5>'] = {
                    function(cmp)
                        cmp.accept({ index = 5 })
                    end,
                    desc = 'Blink: Accept item 5',
                },
            },

            appearance = {
                use_nvim_cmp_as_default = false,
                nerd_font_variant = 'mono',
            },

            fuzzy = { implementation = 'prefer_rust_with_warning' },
            signature = { enabled = true },
            snippets = {},

            sources = {
                default = {
                    'copilot',
                    'avante',
                    'lsp',
                    'path',
                    'snippets',
                    'buffer',
                    'dates',
                    'ripgrep',
                    'emoji',
                    'lazydev',
                },
                providers = {
                    buffer = {
                        score_offset = -3,
                        opts = {
                            get_bufnrs = function()
                                return vim.iter(vim.api.nvim_list_wins())
                                    :map(function(win)
                                        return vim.api.nvim_win_get_buf(win)
                                    end)
                                    :filter(function(buf)
                                        return vim.bo[buf].buftype == ''
                                    end)
                                    :totable()
                            end,
                            use_cache = true,
                        },
                    },
                    path = {
                        score_offset = 3,
                        opts = {
                            trailing_slash = true,
                            get_cwd = function(context)
                                return vim.fn.expand(
                                    ('#%d:p:h'):format(context.bufnr)
                                )
                            end,
                        },
                    },
                    dates = {
                        name = 'Dates',
                        module = 'blink-dates',
                        score_offset = 1000,
                        opts = {
                            weekday_separator = ' ',
                            suggest_short_weekday = false,
                        },
                    },
                    ripgrep = {
                        name = 'Ripgrep',
                        module = 'blink-ripgrep',
                        opts = {
                            prefix_min_len = 3,
                            context_size = 2,
                            max_filesize = '512K',
                        },
                    },
                    emoji = {
                        name = 'Emoji',
                        module = 'blink-emoji',
                        score_offset = 5,
                        opts = { insert = true },
                    },
                    lazydev = {
                        name = 'LazyDev',
                        module = 'lazydev.integrations.blink',
                        score_offset = 50,
                    },
                     copilot = {
                         name = 'copilot',
                         module = 'blink-cmp-copilot',
                         score_offset = 400,
                         min_keyword_length = 0,
                         async = true,
                     },
                     avante = {
                         name = 'Avante',
                         module = 'blink-cmp-avante',
                         score_offset = 300,
                     },

                    cmdline = {
                        name = 'cmdline',
                        module = 'blink.cmp.sources.cmdline',
                    },
                    cmdline_history = {
                        name = 'History',
                        module = 'blink.compat.source',
                    },
                },
            },
        },
    },
}
