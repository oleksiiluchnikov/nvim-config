return {
    {
        'oleksiiluchnikov/vault.nvim',
        -- branch = 'dev',
        dir = '~/projects/vault.nvim',
        opts = function(_, opts)
            local mappings = {
                {
                    '<leader>ns',
                    '<cmd>VaultNotes<CR>',
                    desc = 't: notes',
                    noremap = true,
                },
                {
                    '<leader>nt',
                    '<cmd>VaultTags<CR>',
                    desc = 't: tags',
                    noremap = true,
                },
                {
                    '<leader>nl',
                    '<cmd>VaultLeaves<CR>',
                    desc = 't: leaves',
                    noremap = true,
                },
                {
                    '<leader>no',
                    '<cmd>VaultOrphans<CR>',
                    desc = 't: orphans',
                    noremap = true,
                },
                {
                    '<leader>nr',
                    '<cmd>VaultRandomNote<CR>',
                    desc = 'edit random note',
                    noremap = true,
                },
                {
                    '<leader>p',
                    '<cmd>VaultProperties<CR>',
                    desc = 't: properties',
                    noremap = true,
                },
            }
            require('which-key').add(mappings)

            local mappings_markdown = {
                {
                    '<leader>nno',
                    '<cmd>VaultNoteOutlinks<CR>',
                    desc = 't: open outlinks',
                },
                {
                    '<leader>nni',
                    '<cmd>VaultNoteInlinks<CR>',
                    desc = 't: open inlinks',
                },
                {
                    '<leader>nnd',
                    '<cmd>VaultNoteRename<CR>',
                    desc = 't: rename note',
                },
            }

            vim.api.nvim_create_autocmd('FileType', {
                pattern = 'markdown',
                callback = function(event)
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
                                require('config.utils').uri.encode(vault_name),
                                require('config.utils').uri.encode(
                                    note.data.stem
                                )
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

            --- @type vault.Config.options
            opts = {
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
                    '_docs/*',
                    '_templates/*',
                    '_Legacy/*',
                    'node_modules/*',
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
