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

            -- {
            --     '<D-S-n>',
            --     '<cmd>echo "
            --     desc = 'Create note from selection',
            -- },
            --
            vim.keymap.set('v', '<D-S-n>', function()
                -- ============================================
                -- Get Visual Selection (PROPER METHOD)
                -- ============================================
                local function get_visual_selection()
                    local start_pos = vim.fn.getpos('v')
                    local end_pos = vim.fn.getpos('.')

                    local srow, scol = start_pos[2], start_pos[3]
                    local erow, ecol = end_pos[2], end_pos[3]

                    if srow > erow or (srow == erow and scol > ecol) then
                        srow, erow = erow, srow
                        scol, ecol = ecol, scol
                    end

                    local lines = {}
                    if vim.fn.mode() == 'V' then
                        -- Visual Line Mode
                        lines =
                            vim.api.nvim_buf_get_lines(0, srow - 1, erow, false)
                        scol, ecol = 1, #lines[#lines] + 1
                    elseif srow == erow then
                        lines =
                            { string.sub(vim.fn.getline(srow), scol, ecol - 1) }
                    else
                        lines = vim.api.nvim_buf_get_text(
                            0,
                            srow - 1,
                            scol - 1,
                            erow - 1,
                            ecol,
                            {}
                        )
                    end

                    local text = table.concat(lines, '\n')

                    return {
                        text = text,
                        start_line = srow - 1, -- 0-indexed
                        start_col = scol - 1, -- 0-indexed
                        end_line = erow - 1, -- 0-indexed
                        end_col = ecol, -- exclusive end
                    }
                end

                -- ============================================
                -- Configuration
                -- ============================================
                local config = {
                    get_vault_root = function()
                        local ok, vault_config = pcall(require, 'vault.config')
                        if
                            ok
                            and vault_config.options
                            and vault_config.options.root
                        then
                            return vault_config.options.root
                        end
                        return nil
                    end,
                    max_title_length = 120,
                    show_success_notification = true,
                    file_extension = '.md',
                    prompt_for_name = false,
                }

                -- ============================================
                -- Sanitize Title for Filename
                -- ============================================
                local function sanitize_filename(text, max_length)
                    if not text or text == '' then
                        return nil
                    end

                    local sanitized = text
                        :gsub('\r\n', ' ')
                        :gsub('\n', ' ')
                        :gsub('\t', ' ')
                        :gsub('%s+', ' ')
                        :match('^%s*(.-)%s*$')
                        -- cleanup if "#+ " present at start
                        :gsub(
                            '^#+%s*',
                            ''
                        )

                    if not sanitized or sanitized == '' then
                        return nil
                    end

                    sanitized = sanitized
                        :sub(1, max_length)
                        :gsub('[<>:"/\\|?*]', '')
                        :gsub('[%c]', '')
                        :gsub('%s+', ' ')
                        :match('^%s*(.-)%s*$')

                    return sanitized ~= '' and sanitized or nil
                end

                -- ============================================
                -- Find Unique Filename
                -- ============================================
                local function find_unique_filename(
                    vault_root,
                    base_title,
                    extension
                )
                    local counter = 0

                    while true do
                        local title = counter == 0 and base_title
                            or (base_title .. ' ' .. counter)
                        local filepath = vault_root .. '/' .. title .. extension

                        local stat = vim.loop.fs_stat(filepath)
                        if not stat then
                            return {
                                filepath = filepath,
                                title = title,
                                base_title = base_title,
                                counter = counter,
                            }
                        end

                        counter = counter + 1

                        if counter > 9999 then
                            return nil
                        end
                    end
                end

                -- ============================================
                -- Create Note File
                -- ============================================
                local function create_note(filepath, content)
                    local parent_dir = vim.fn.fnamemodify(filepath, ':h')
                    local mkdir_ok = vim.fn.mkdir(parent_dir, 'p')

                    if mkdir_ok == 0 then
                        return false,
                            'Failed to create parent directory: ' .. parent_dir
                    end

                    local lines = vim.split(content, '\n', { plain = true })
                    local write_ok = vim.fn.writefile(lines, filepath)

                    if write_ok ~= 0 then
                        return false, 'Failed to write file: ' .. filepath
                    end

                    return true
                end

                -- ============================================
                -- Main Logic
                -- ============================================

                -- Get vault root
                local vault_root = config.get_vault_root()
                if not vault_root then
                    vim.notify(
                        'Could not determine vault root. Ensure vault.config is configured.',
                        vim.log.levels.ERROR
                    )
                    return
                end

                vault_root = vault_root:gsub('/$', '')

                -- Validate vault exists
                local vault_stat = vim.loop.fs_stat(vault_root)
                if not vault_stat or vault_stat.type ~= 'directory' then
                    vim.notify(
                        string.format(
                            'Vault root does not exist or is not a directory: %s',
                            vault_root
                        ),
                        vim.log.levels.ERROR
                    )
                    return
                end

                -- Get visual selection
                local selection = get_visual_selection()
                if not selection then
                    vim.notify('No valid text selected', vim.log.levels.WARN)
                    return
                end

                vim.notify(
                    string.format(
                        'Visual selection: %s',
                        vim.inspect(selection)
                    ),
                    vim.log.levels.DEBUG
                )

                -- Validate non-empty
                if selection.text:match('^%s*$') then
                    vim.notify(
                        'Selection contains only whitespace',
                        vim.log.levels.WARN
                    )
                    return
                end

                -- Extract first line for title
                local first_line =
                    vim.split(selection.text, '\n', { plain = true })[1]
                if not first_line or first_line:match('^%s*$') then
                    vim.notify(
                        'First line is empty, cannot generate title',
                        vim.log.levels.WARN
                    )
                    return
                end

                -- Generate sanitized title
                local base_title =
                    sanitize_filename(first_line, config.max_title_length)
                if not base_title then
                    vim.notify(
                        'Could not generate valid filename from first line',
                        vim.log.levels.WARN
                    )
                    return
                end

                -- ============================================
                -- Prompt for Title (Optional)
                -- ============================================
                if config.prompt_for_name then
                    -- Use nui.nvim to prompt for title
                    local Input = require('nui.input')
                    local title_input = Input({
                        position = '50%',
                        size = { width = 50 },
                        border = {
                            style = 'rounded',
                            text = {
                                top = ' Enter Note Title ',
                                top_align = 'center',
                            },
                        },
                        buf_options = {
                            modifiable = true,
                            readonly = false,
                            filetype = 'text',
                            buftype = 'prompt',
                            swapfile = false,
                            bufhidden = 'wipe',
                        },
                        win_options = {
                            winhighlight = 'Normal:Normal,FloatBorder:FloatBorder',
                        },
                    })

                    title_input:mount()

                    local title_result = nil
                    title_input:on('submit', function(value)
                        title_result = value
                        title_input:unmount()
                    end)
                    title_input:on('close', function()
                        title_input:unmount()
                    end)
                    -- Wait for user input
                    vim.wait(10000, function()
                        return not title_input:is_mounted()
                    end, 100)

                    if title_result and title_result ~= '' then
                        local prompted_title = sanitize_filename(
                            title_result,
                            config.max_title_length
                        )
                        if prompted_title and prompted_title ~= '' then
                            base_title = prompted_title
                        else
                            vim.notify(
                                'Prompted title is invalid, using default title',
                                vim.log.levels.WARN
                            )
                        end
                    else
                        vim.notify(
                            'No title entered, using default title',
                            vim.log.levels.INFO
                        )
                    end
                end

                -- Find unique filename
                local file_info = find_unique_filename(
                    vault_root,
                    base_title,
                    config.file_extension
                )
                if not file_info then
                    vim.notify(
                        'Could not find unique filename after 9999 attempts',
                        vim.log.levels.ERROR
                    )
                    return
                end

                vim.notify(
                    string.format(
                        'Creating note at: %s',
                        vim.inspect(file_info)
                    ),
                    vim.log.levels.DEBUG
                )

                -- Create note file
                local success, err =
                    create_note(file_info.filepath, selection.text)
                if not success then
                    vim.notify(
                        string.format(
                            'Failed to create note: %s',
                            err or 'unknown error'
                        ),
                        vim.log.levels.ERROR
                    )
                    return
                end

                -- Replace selection with wikilink
                -- Wikilink format: [[Title]]

                local wikilink = string.format('[[%s]]', file_info.title)

                vim.notify(
                    'Replacing selection with wikilink: ' .. wikilink,
                    vim.log.levels.DEBUG
                )

                -- dont use nvim_buf_set_text to preserve registers
                -- instead use normal mode commands
                vim.api.nvim_feedkeys(
                    vim.api.nvim_replace_termcodes(
                        -- Use cmd to replace visual selection with wikilink
                        'c'
                            .. wikilink
                            .. '<Esc>',
                        true,
                        false,
                        true
                    ),
                    'n',
                    false
                )

                -- Success notification
                if config.show_success_notification then
                    local msg = file_info.counter > 0
                            and string.format(
                                'Created note: "%s" (variant %d)',
                                file_info.base_title,
                                file_info.counter
                            )
                        or string.format('Created note: "%s"', file_info.title)

                    vim.notify(msg, vim.log.levels.INFO)
                end
            end, {
                desc = 'Create Obsidian note from visual selection',
                silent = true,
                noremap = true,
            })

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
