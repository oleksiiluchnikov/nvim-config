return {
    chat = {
        adapter = 'opencode_claude',
        roles = {
            user = 'Oleksii Luchnikov',
        },
    },

    -- ========================================================
    -- VARIABLES (Context Insertion)
    -- ========================================================
    variables = {
        ['buffer'] = {
            opts = {
                contains_code = true,
                default_params = 'diff', -- 'all' | 'diff'
                has_params = true,
            },
        },
        ['lsp'] = {
            opts = {
                contains_code = true,
            },
        },
        ['viewport'] = {
            opts = {
                contains_code = true,
            },
        },
    },

    -- ========================================================
    -- TOOLS CONFIGURATION (Fullstack Development)
    -- ========================================================

    -- ========================================================
    -- KEYMAPS & SLASH COMMANDS
    -- ========================================================
    -- keymaps = {
    --     send = {
    --         modes = { n = '<CR>' },
    --         description = 'Send',
    --         callback = function(chat)
    --             chat:apply_model(
    --                 vim.g.codecompanion_initial_openrouter_model
    --             )
    --             chat:submit()
    --         end,
    --     },
    -- },
    slash_commands = {
        ['git_files'] = {
            description = 'List git files',
            ---@param chat CodeCompanion.Chat
            callback = function(chat)
                local handle = io.popen('git ls-files')
                if handle ~= nil then
                    local result = handle:read('*a')
                    handle:close()
                    chat:add_reference(
                        { content = result },
                        'git',
                        '<git_files>'
                    )
                else
                    return vim.notify(
                        'No git files available',
                        vim.log.levels.INFO,
                        { title = 'CodeCompanion' }
                    )
                end
            end,
            opts = {
                contains_code = false,
            },
        },
        ['buffer'] = {
            keymaps = { modes = { i = '<C-b>' } },
            opts = { provider = 'telescope' },
        },
        ['file'] = {
            keymaps = { modes = { i = '<C-p>' } },
            opts = {
                provider = 'telescope',
                contains_code = true,
                max_lines = 1000,
            },
        },
        ['fetch'] = {
            keymaps = { modes = { i = '<C-f>' } },
            opts = { adapter = 'jina' },
        },
        ['help'] = {
            opts = {
                provider = 'telescope',
                max_lines = 128,
            },
        },
        ['image'] = {
            keymaps = { modes = { i = '<C-i>' } },
            opts = { dirs = { '~/Documents/Screenshots' } },
        },
        ['rules'] = {
            opts = { contains_code = true },
        },
        ['symbols'] = {
            opts = { provider = 'telescope' },
        },
        ['quickfix'] = {
            opts = { contains_code = true },
        },
    },
    inline = {
        adapter = 'claude_code',
    },
    cmd = {
        adapter = 'opencode',
    },
}
