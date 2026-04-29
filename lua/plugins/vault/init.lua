return {
    {
        'oleksiiluchnikov/teolog.nvim',
        dir = '~/projects/teolog.nvim',
        lazy = false,
    },
    {
        'oleksiiluchnikov/vimtable.nvim',
        dir = '~/projects/vimtable.nvim',
        lazy = true, -- loaded on demand by grid_editor
    },
    {
        'oleksiiluchnikov/vault.nvim',
        -- branch = 'dev',
        dir = '~/projects/vault.nvim',
        dependencies = {
            'oleksiiluchnikov/teolog.nvim',
            'oleksiiluchnikov/vimtable.nvim',
        },
        opts = function(_, opts)
            local mappings = {
                {
                    '<leader>ns',
                    '<cmd>Vault notes<CR>',
                    desc = 't: notes',
                    noremap = true,
                },
                {
                    '<leader>nt',
                    '<cmd>Vault tags<CR>',
                    desc = 't: tags',
                    noremap = true,
                },
                {
                    '<leader>nl',
                    '<cmd>Vault notes leaves<CR>',
                    desc = 't: leaves',
                    noremap = true,
                },
                {
                    '<leader>no',
                    '<cmd>Vault notes orphans<CR>',
                    desc = 't: orphans',
                    noremap = true,
                },
                {
                    '<leader>nr',
                    '<cmd>Vault note random<CR>',
                    desc = 'edit random note',
                    noremap = true,
                },
                {
                    '<leader>p',
                    '<cmd>Vault properties<CR>',
                    desc = 't: properties',
                    noremap = true,
                },
            }
            require('which-key').add(mappings)

            local vault_wikilink_actions = require('plugins.vault.resolve_wikilink_under_cursor')

            local mappings_markdown = {
                {
                    '<M-n>',
                    '<cmd>Vault note new<CR>',
                    desc = 'vault: new note',
                    noremap = true,
                },
                {
                    '<leader>nno',
                    '<cmd>Vault note outlinks<CR>',
                    desc = 't: open outlinks',
                },
                {
                    '<leader>nni',
                    '<cmd>Vault note inlinks<CR>',
                    desc = 't: open inlinks',
                },
                {
                    '<leader>nnd',
                    '<cmd>Vault note rename<CR>',
                    desc = 't: rename note',
                },
                {
                    'gd',
                    vault_wikilink_actions.resolve_under_cursor,
                    desc = 'vault: resolve wikilink under cursor',
                },
                {
                    'gf',
                    vault_wikilink_actions.follow_under_cursor,
                    desc = 'vault: follow wikilink',
                },
                {
                    '<leader>nnv',
                    function()
                        vault_wikilink_actions.follow_under_cursor({ split = 'vertical' })
                    end,
                    desc = 'vault: follow wikilink in vertical split',
                },
                {
                    '<leader>nnw',
                    vault_wikilink_actions.rename_wikilink_under_cursor,
                    desc = 'vault: rename wikilink only',
                },
                {
                    '<leader>nnR',
                    vault_wikilink_actions.rename_note_under_cursor,
                    desc = 'vault: rename linked note + update wikilinks',
                },

                {
                    '<D-e>',
                    function()
                        -- write, bd, open in obsidian
                        vim.api.nvim_command('write')
                        require('vault.notes.note')(vim.fn.expand('%:p')):open_in_obsidian()
                        vim.api.nvim_command('bdelete!')
                    end,
                    desc = 'Open note in Obsidian',
                },
            }

            vim.keymap.set(
                'v',
                '<D-S-n>',
                require('plugins.vault.create_note_from_selection').create,
                {
                    desc = 'Create Obsidian note from visual selection',
                    silent = true,
                    noremap = true,
                }
            )

            vim.api.nvim_create_autocmd('FileType', {
                pattern = 'markdown',
                callback = function()
                    local function open_note_in_obsidian()
                        local note =
                            require('vault.notes.note')(vim.fn.expand('%:p'))
                        local vault_name = vim.fn.fnamemodify(
                            require('vault.config').options.root,
                            ':t'
                        )
                        vim.fn.system(
                            string.format(
                                'open \'obsidian://open?vault=%s&file=%s\'',
                                require('config.lib').uri.encode(vault_name),
                                require('config.lib').uri.encode(note.data.stem)
                            )
                        )
                    end
                    table.insert(mappings_markdown, {
                        '<leader>nne',
                        open_note_in_obsidian,
                        desc = 't: rename note',
                    })
                    require('which-key').add(mappings_markdown)
                end,
            })

            local dates = require('dates')

            local function normalize_vault_date(value)
                local text = tostring(value):match('^"?(.-)"?$')
                    or tostring(value)
                text = vim.trim(text)

                local compact = text:gsub('[^%d]', '')
                if #compact < 8 then
                    return compact
                end

                local year = compact:sub(1, 4)
                local month = compact:sub(5, 6)
                local day = compact:sub(7, 8)

                if month == '00' then
                    month = '01'
                end
                if day == '00' then
                    day = '01'
                end

                local iso = string.format('%s-%s-%s', year, month, day)
                if not dates.is_valid_string(iso) then
                    return compact
                end

                return iso:gsub('%-', '') .. '000000'
            end

            --- @type vault.Config.options
            opts = {
                log = { level = 'warn', file = true },
                root = '~/knowledge', -- The root directory of the vault.
                features = {
                    commands = true,
                    cmp = true,
                },
                dirs = {
                    docs = '_docs',
                    templates = 'Templates',
                    journal = {
                        root = 'Daily',
                        daily = 'Daily',
                    },
                },
                ignore = {
                    '.git/*',
                    '.obsidian/*',
                    '.trash/*',
                },
                ext = '.md',
                tags = {
                    valid = {
                        hex = true, -- Hex is a valid tag.
                    },
                },
                search_pattern = {
                    tag = '#([A-Za-z0-9/_-]+)[\r|%s|\n|$]',
                    wikilink = '%[%[([^\\]]*)%]%]',
                    note = {
                        type = 'class::%s#class/([A-Za-z0-9_-]+)',
                    },
                },
                search_tool = 'rg', -- The search tool to use. Default: "rg"
                notify = {
                    on_write = true,
                },
                telescope = {
                    prewarm = false,
                },
                duplicates = {
                    ignored_frontmatter_keys = { 'modified', 'committed' },
                    stem_suffix_patterns = {
                        [[\s\+\d\+$]],
                        [[_\d\+$]],
                    },
                    review_excluded_patterns = {
                        [[^Ai/]],
                        [[README\.md$]],
                    },
                    related_excluded_patterns = {
                        [[^Daily/]],
                        [[^Ai/]],
                        [[README\.md$]],
                    },
                    frontmatter_normalizers = {
                        created = normalize_vault_date,
                        committed = normalize_vault_date,
                        modified = normalize_vault_date,
                    },
                },
                merge = {
                    ignored_conflict_fields = { 'modified', 'committed' },
                    field_normalizers = {
                        assignee = function(value)
                            return tostring(value):gsub(
                                '_Legacy/_docs/person/oleksii_luchnikov',
                                'Person %- Oleksii Luchnikov'
                            )
                        end,
                        created = normalize_vault_date,
                        committed = normalize_vault_date,
                        modified = normalize_vault_date,
                    },
                },
                tasks = {
                    dir = 'Tasks',
                    fields = {
                        status = 'status',
                        priority = 'priority',
                        blocked_by = 'blocked_by',
                    },
                    defaults = {
                        status = '[[Status - Backlog]]',
                        executor = '[[Executor - Human]]',
                        category = '[[Category - Green Task]]',
                        priority = '[[Priority - Medium]]',
                    },
                    status_order = {
                        'Status - Backlog',
                        'Status - Todo',
                        'Status - In-Progress',
                        'Status - In-Review',
                        'Status - Done',
                        'Status - Failed',
                        'Status - Deprecated',
                        'Status - Archived',
                    },
                },
                views = {
                    grid = {
                        default_columns = { 'slug', 'title', 'status', 'tags' },
                        identity_mode = 'conceal',
                    },
                },
                -- popups = {
                --     fleeting_note = {
                --         title = {
                --             text = 'Fleeting Note',
                --             preview = 'border', -- "border" | "prompt" | "none"
                --         },
                --         editor = { -- @see :h nui.popup
                --             position = {
                --                 row = math.floor(vim.o.lines / 2) - 9,
                --                 col = math.floor(vim.o.columns / 2) - 40,
                --             },
                --             size = {
                --                 height = 6,
                --                 width = 80,
                --             },
                --             enter = true,
                --             focusable = true,
                --             zindex = 60,
                --             relative = 'editor',
                --             border = {
                --                 padding = {
                --                     top = 0,
                --                     bottom = 0,
                --                     left = 0,
                --                     right = 0,
                --                 },
                --                 -- T shape side border: ├
                --                 style = 'rounded',
                --             },
                --             buf_options = {
                --                 modifiable = true,
                --                 readonly = false,
                --                 filetype = 'markdown',
                --                 buftype = 'nofile',
                --                 swapfile = false,
                --                 bufhidden = 'wipe',
                --             },
                --             win_options = {
                --                 winhighlight = 'Normal:Normal,FloatBorder:FloatBorder',
                --             },
                --         },
                --         prompt = {
                --             hidden = true,
                --             size = {
                --                 height = 0.8,
                --                 width = 0.8,
                --             },
                --         },
                --         results = {
                --             size = {
                --                 height = 10,
                --                 width = 80,
                --             },
                --         },
                --     },
                -- },
            }

            return opts
        end,
    },
}
