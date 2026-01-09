-- lua/plugins/codecompanion/init.lua
-- CodeCompanion + OpenRouter Configuration

-- ============================================================================
-- GLOBAL SETTINGS
-- ============================================================================
vim.g.codecompanion_auto_tool_mode = true
vim.g.codecompanion_yolo_mode = true
vim.g.codecompanion_prompt_decorator = true
vim.g.codecompanion_attached_prompt_decorator = false

-- OpenRouter Configuration
vim.g.codecompanion_initial_adapter = 'opencode_claude'
vim.g.codecompanion_initial_openrouter_model = 'claude-sonnet-4-5'

-- ============================================================================
-- DEFAULT TOOLS & GROUPS
-- ============================================================================
local default_tools = {
    'read_file',
    'create_file',
    'cmd_runner',
    'insert_edit_into_file',
}

local default_groups = {
    'sequentialthinking',
    'linkup',
    'neovim',
}

local function get_runtime_dir()
    return vim.fn.stdpath('data')
end

-- ============================================================================
-- PLUGIN CONFIGURATION
-- ============================================================================
return {
    {
        'olimorris/codecompanion.nvim',
        event = 'VeryLazy',
        cmd = {
            'CodeCompanion',
            'CodeCompanionChat',
            'CodeCompanionActions',
        },
        dependencies = {
            'j-hui/fidget.nvim',
            'nvim-lua/plenary.nvim',
            {
                'MeanderingProgrammer/render-markdown.nvim',
                ft = { 'markdown', 'codecompanion' },
            },
            {
                'echasnovski/mini.diff',
                config = function()
                    require('mini.diff').setup({
                        source = require('mini.diff').gen_source.none(),
                    })
                end,
            },
            'nvim-treesitter/nvim-treesitter',
        },
        config = function()
            require('plugins.codecompanion.autocmds')
            -- ====================================================================
            -- MAIN SETUP
            -- ====================================================================
            require('codecompanion').setup({
                adapters = require('plugins.codecompanion.adapters'),
                opts = {
                    system_prompt = require(
                        'plugins.codecompanion.system-prompt'
                    ),
                    log_level = 'INFO', -- DEBUG, TRACE for troubleshooting
                    language = 'English',
                    send_code = true,
                },

                -- ================================================================
                -- INTERACTIONS
                -- ================================================================
                interactions = require('plugins.codecompanion.interactions'),

                -- ================================================================
                -- DISPLAY SETTINGS
                -- ================================================================

                -- ================================================================
                -- ADAPTERS
                -- ================================================================
                prompt_library = (function()
                    local custom_prompts =
                        require('plugins.codecompanion.prompt_library')
                    --
                    -- -- Add config options to the prompts table
                    -- custom_prompts.show_preset_prompts = true
                    -- custom_prompts.markdown = {
                    --     dirs = { vim.fn.expand('~/prompts') },
                    -- }
                    --
                    return custom_prompts
                end)(),

                -- ================================================================
                -- RULES (Auto-load project context files)
                -- ================================================================
                rules = {
                    default = {
                        description = 'Collection of common project files',
                        files = {
                            '.clinerules',
                            '.cursorrules',
                            '.goosehints',
                            '.rules',
                            '.windsurfrules',
                            '.github/copilot-instructions.md',
                            'AGENT.md',
                            'AGENTS.md',
                            { path = 'CLAUDE.md', parser = 'claude' },
                            { path = 'CLAUDE.local.md', parser = 'claude' },
                            { path = '~/.claude/CLAUDE.md', parser = 'claude' },
                        },
                        is_preset = true,
                    },
                    opts = {
                        chat = {
                            enabled = true,
                            autoload = 'default',
                        },
                    },
                },
                display = {
                    chat = {
                        show_references = true,
                        show_settings = false,
                        show_reasoning = true,
                        fold_reasoning = true,
                        fold_context = true,
                        icons = {
                            tool_success = '󰸞 ',
                            chat_fold = ' ',
                        },
                    },
                    diff = {
                        provider = 'mini_diff',
                    },
                    actions_palette = {
                        show_preset_actions = true,
                    },
                },

                extensions = {
                    history = {
                        enabled = true,
                        opts = {
                            keymap = 'gh',
                            auto_generate_title = true,
                            continue_last_chat = false,
                            delete_on_clearing_chat = false,
                            picker = 'snacks',
                            enable_logging = false,
                            dir_to_save = get_runtime_dir()
                                .. '/codecompanion-history',
                            auto_save = true,
                            save_chat_keymap = 'sc',
                        },
                    },
                    mcphub = {
                        callback = 'mcphub.extensions.codecompanion',
                        opts = {
                            make_vars = true,
                            make_slash_commands = true,
                            show_result_in_chat = true,
                        },
                    },
                    vectorcode = {
                        opts = {
                            add_tool = true,
                        },
                    },
                },
            })

            -- ====================================================================
            -- KEYMAPS
            -- ====================================================================
            vim.keymap.set(
                { 'n', 'v' },
                '<leader>ck',
                '<cmd>CodeCompanionActions<cr>',
                {
                    noremap = true,
                    silent = true,
                    desc = 'CodeCompanion Actions',
                }
            )

            vim.keymap.set(
                { 'n', 'v' },
                '<leader>cc',
                '<cmd>CodeCompanionChat Toggle<cr>',
                { noremap = true, silent = true, desc = 'Toggle Chat' }
            )

            vim.keymap.set(
                'v',
                '<leader>ctx',
                '<cmd>CodeCompanionChat Add<cr>',
                { noremap = true, silent = true, desc = 'Add to Chat' }
            )

            -- Neovim Expert Mode
            vim.keymap.set('n', '<leader>cne', function()
                require('codecompanion').chat({
                    tools = { groups = { 'neovim_expert' } },
                })
            end, {
                noremap = true,
                silent = true,
                desc = 'Neovim Expert Chat',
            })

            vim.api.nvim_create_user_command('GitCommitMsg', function()
                require('codecompanion').prompt('detailcommit')
            end, { desc = 'Generate detailed git commit message' })

            vim.api.nvim_create_user_command('GitCommitQuick', function()
                require('codecompanion').prompt('qcommit')
            end, { desc = 'Generate quick commit message' })

            -- Command line abbreviation
            vim.cmd([[cab cc CodeCompanion]])
        end,
    },
    {
        'ravitemer/codecompanion-history.nvim',
        cmd = { 'CodeCompanionHistory' },
    },
    {
        'Davidyz/VectorCode',
        version = '*',
        dependencies = { 'nvim-lua/plenary.nvim' },
        build = 'pipx upgrade vectorcode',
        opts = {
            n_query = 1,
            async_opts = {
                notify = true,
            },
        },
        cmd = { 'VectorCode' },
    },
}
