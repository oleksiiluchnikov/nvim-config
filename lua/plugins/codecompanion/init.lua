-- Configuration Module for CodeCompanion
-- Setup: OpenRouter with Reasoning, Local Ollama, and Cloud Providers

-- 5. PLUGIN SPECIFICATION
return {
    {
        'olimorris/codecompanion.nvim',
        cmd = { 'CodeCompanion', 'CodeCompanionChat', 'CodeCompanionActions' },
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
        },
        config = function()
            local opts = {
                ignore_warnings = true,
                adapters = {
                    http = {
                        openrouter = function()
                            local openrouter = require(
                                'plugins.codecompanion.adapters.openrouter'
                            )
                            return require('codecompanion.adapters').extend(
                                openrouter,
                                {
                                    name = 'openrouter',
                                    formatted_name = 'Openrouter',
                                    env = {
                                        url = 'https://openrouter.ai/api',
                                        api_key = 'cmd:pass api/openrouter',
                                    },
                                    schema = {
                                        model = {
                                            default = 'anthropic/claude-opus-4.5',
                                        },
                                    },
                                }
                            )
                        end,
                    },
                },
                strategies = {
                    chat = {
                        adapter = 'openrouter', -- Set your default here
                        roles = { user = 'Oleksii Luchnikov' },
                        slash_commands = {
                            ['image'] = {
                                opts = { dirs = { '~/Documents/Screenshots' } },
                            },
                        },
                        tools = {
                            opts = {
                                auto_submit_errors = true,
                            },
                        },
                    },
                    inline = {
                        adapter = 'copilot',
                    },
                },
                display = {
                    action_palette = {
                        provider = 'telescope',
                    },
                    inline = {
                        layout = 'vertical',
                        hl_group = 'CodeCompanionInline',
                    },
                    chat = {
                        show_references = true,
                        show_settings = false,
                        show_reasoning = false,
                        fold_reasoning = false,
                        icons = {
                            tool_success = '󰸞 ',
                            chat_fold = ' ',
                        },
                        fold_context = true,
                    },
                    diff = {
                        provider = 'mini_diff',
                    },
                },
            }
            require('codecompanion').setup(opts)
        end,
        keys = {
            {
                '<C-a>',
                '<cmd>CodeCompanionActions<CR>',
                desc = 'Open the action palette',
                mode = { 'n', 'v' },
            },
            {
                '<leader>j',
                '<cmd>CodeCompanionChat Toggle<CR>',
                desc = 'Toggle a chat buffer',
                mode = { 'n', 'v' },
            },
            {
                '<leader>x',
                '<cmd>CodeCompanionChat Add<CR>',
                desc = 'Add code to a chat buffer',
                mode = { 'v' },
            },
            {
                'ga',
                '<cmd>CodeCompanionChat Add<CR>',
                desc = 'Add code to a chat buffer',
                mode = { 'v' },
            },
            {
                '<leader>jl',
                function()
                    require('codecompanion').last_chat()
                end,
                desc = 'Open last chat',
                mode = 'n',
            },
            {
                '<leader>jr',
                function()
                    require('codecompanion').restore(vim.fn.get_bufnrs()[1])
                end,
                desc = 'Restore chat',
                mode = 'n',
            },
        },
    },
}
