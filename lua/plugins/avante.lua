return {
    {
        'yetone/avante.nvim',
        event = 'VeryLazy',
        version = false, -- Important: Never set this to "*"!
        opts = {
            ---@alias Provider "claude" | "openai" | "azure" | "gemini" | "cohere" | "copilot" | string
            provider = 'gemini_3_flash', -- Updated: The default provider
            ---@alias Mode "agentic" | "legacy"
            mode = 'agentic', -- New: The default mode for interaction
            auto_suggestions_provider = 'copilot', -- For auto-suggestions

            acp_providers = {
                ['opencode'] = {
                    command = 'opencode',
                    args = { 'acp' },
                    env = {
                        OPENCODE_API_KEY = os.getenv('OPENCODE_API_KEY'),
                    },
                },
            },
            providers = {
                ---@type AvanteProvider
                copilot = {
                    timeout = 5000,
                    extra_request_body = {
                        temperature = 0.75, -- Updated default
                        max_tokens = 4096,
                    },
                },
                openai = {
                    endpoint = 'https://openrouter.ai/api/v1',
                    model = 'openai/gpt-5.1', -- Updated model
                    api_key_name = 'OPENROUTER_API_KEY',
                    extra_request_body = {
                        timeout = 30000, -- New: for reasoning models
                        max_completion_tokens = 8192, -- New: for reasoning models
                        reasoning_effort = 'high', -- New: for reasoning models
                    },
                },
                ['gpt-5'] = {
                    endpoint = 'https://openrouter.ai/api/v1',
                    model = 'openai/gpt-5', -- Updated model
                    api_key_name = 'OPENROUTER_API_KEY',
                    extra_request_body = {
                        timeout = 30000, -- New: for reasoning models
                        max_completion_tokens = 8192, -- New: for reasoning models
                        reasoning_effort = 'high', -- New: for reasoning models
                    },
                },
                ['copilot-gemini'] = {
                    __inherited_from = 'copilot',
                    model = 'gemini-2.0-flash-001',
                },
                ['copilot-claude37-thought'] = {
                    __inherited_from = 'copilot',
                    model = 'claude-3.7-sonnet-thought',
                },
                ['copilot-claude35'] = {
                    __inherited_from = 'copilot',
                    model = 'claude-3.5-sonnet',
                },
                ['copilot-claude37'] = {
                    __inherited_from = 'copilot',
                    model = 'claude-3.7-sonnet',
                },
                ['copilot_gpt'] = {
                    __inherited_from = 'copilot',
                    model = 'gpt-5-mini',
                },

                -- deepseek provider (keeps its own model)
                ['deepseek_14b'] = {
                    __inherited_from = 'ollama',
                    model = 'deepseek-r1:14b',
                },

                -- Additional top-level providers (moved out from deepseek_14b)
                sonnet = {
                    __inherited_from = 'openai',
                    model = 'anthropic/claude-sonnet-4',
                    api_key_name = 'OPENROUTER_API_KEY',
                    endpoint = 'https://openrouter.ai/api/v1',
                    timeout = 5000,
                    extra_request_body = {
                        max_tokens = 4096,
                    },
                },

                opus = {
                    __inherited_from = 'openai',
                    model = 'anthropic/claude-opus-4',
                    api_key_name = 'OPENROUTER_API_KEY',
                    endpoint = 'https://openrouter.ai/api/v1',
                    extra_request_body = {
                        max_tokens = 4096,
                    },
                },

                openrouter_cs35 = {
                    __inherited_from = 'openai',
                    api_key_name = 'OPENROUTER_API_KEY',
                    endpoint = 'https://openrouter.ai/api/v1',
                    model = 'anthropic/claude-3.5-sonnet:beta',
                    extra_request_body = {
                        temperature = 0.2,
                        max_tokens = 8192,
                    },
                },

                gemini_pro = {
                    __inherited_from = 'openai',
                    model = 'google/gemini-2.5-pro-preview',
                    api_key_name = 'OPENROUTER_API_KEY',
                    endpoint = 'https://openrouter.ai/api/v1',
                },

                gemini_3_flash = {
                    __inherited_from = 'openai',
                    model = 'google/gemini-3-flash-preview',
                    api_key_name = 'OPENROUTER_API_KEY',
                    endpoint = 'https://openrouter.ai/api/v1',
                },

                cody = {
                    endpoint = 'https://sourcegraph.com',
                    model = 'anthropic::2024-10-22::claude-3-5-sonnet-latest',
                    api_key_name = 'SRC_ACCESS_TOKEN',
                    parse_curl_args = function(provider_opts, prompt_opts)
                        local headers = {
                            ['Content-Type'] = 'application/json',
                            ['Authorization'] = 'token '
                                .. os.getenv('SRC_ACCESS_TOKEN'),
                        }
                        return {
                            url = 'https://sourcegraph.com/.api/completions/stream?api-version=2&client-name=web&client-version=0.0.1',
                            timeout = 30000,
                            insecure = false,
                            headers = headers,
                            body = vim.tbl_deep_extend('force', {
                                model = 'anthropic::2024-10-22::claude-3-5-sonnet-latest',
                                temperature = 0,
                                topK = -1,
                                topP = -1,
                                maxTokensToSample = 4000,
                                stream = true,
                                messages = function(opts)
                                    local messages = {
                                        {
                                            role = 'system',
                                            content = opts.system_prompt,
                                        },
                                    }
                                    vim.iter(opts.messages):each(function(msg)
                                        table.insert(messages, {
                                            speaker = msg.role == 'user'
                                                    and 'human'
                                                or msg.role,
                                            text = msg.content,
                                        })
                                    end)
                                    return messages
                                end,
                            }, {}),
                        }
                    end,
                    parse_response = function(data_stream, event_state, opts)
                        if event_state == 'done' then
                            opts.on_complete()
                            return
                        end
                        if data_stream == nil or data_stream == '' then
                            return
                        end
                        local json = vim.json.decode(data_stream)
                        local delta = json.deltaText
                        local stopReason = json.stopReason
                        if stopReason == 'end_turn' then
                            return
                        end
                        opts.on_chunk(delta)
                    end,
                },
            },

            -- Updated dual_boost configuration
            dual_boost = {
                enabled = false,
                first_provider = 'openai',
                second_provider = 'claude',
                prompt = 'Based on the two reference outputs below, generate a response that incorporates elements from both but reflects your own judgment and unique perspective. Do not provide any explanation, just give the response directly. Reference Output 1: [{{provider1_output}}], Reference Output 2: [{{provider2_output}}]',
                timeout = 60000,
            },

            behaviour = {
                auto_suggestions = false,
                auto_set_highlight_group = true,
                auto_set_keymaps = true,
                auto_apply_diff_after_generation = false,
                support_paste_from_clipboard = false,
                minimize_diff = true, -- New: remove unchanged lines when applying code blocks
                enable_token_counting = true, -- New: enable token counting
                auto_approve_tool_permissions = false, -- New: tool permission handling
            },

            mappings = {
                diff = {
                    ours = 'co',
                    theirs = 'ct',
                    all_theirs = 'ca',
                    both = 'cb',
                    cursor = 'cc',
                    next = ']x',
                    prev = '[x',
                },
                suggestion = {
                    accept = '<M-l>', -- New mappings
                    next = '<M-]>',
                    prev = '<M-[>',
                    dismiss = '<C-]>',
                },
                jump = {
                    next = ']]',
                    prev = '[[',
                },
                submit = {
                    normal = '<CR>',
                    insert = '<C-s>',
                },
                cancel = { -- New: cancel mappings
                    normal = { '<C-c>', '<Esc>', 'q' },
                    insert = { '<C-c>' },
                },
                sidebar = {
                    apply_all = 'A',
                    apply_cursor = 'a',
                    retry_user_request = 'r', -- New
                    edit_user_request = 'e', -- New
                    switch_windows = '<Tab>',
                    reverse_switch_windows = '<S-Tab>',
                    remove_file = 'd', -- New
                    add_file = '@', -- New
                    close = { '<Esc>', 'q' }, -- New
                },
            },

            hints = { enabled = true },

            windows = {
                position = 'right',
                wrap = true,
                width = 30, -- Updated default from 50 to 30
                sidebar_header = {
                    enabled = true, -- Changed from false to true
                    align = 'center',
                    rounded = true,
                },
                input = {
                    prefix = '> ',
                    height = 8, -- Updated from 30 to 8
                },
                edit = {
                    border = 'rounded',
                    start_insert = true,
                },
                ask = {
                    floating = false, -- Changed from true to false
                    start_insert = true,
                    border = 'rounded',
                    focus_on_apply = 'ours',
                },
            },

            highlights = {
                diff = {
                    current = 'DiffText',
                    incoming = 'DiffAdd',
                },
            },

            diff = {
                autojump = true,
                list_opener = 'copen',
                override_timeoutlen = 500,
            },

            -- New: Selector configuration (replaces file_selector)
            selector = {
                provider = 'fzf_lua', -- Updated from 'fzf' to 'fzf_lua'
                provider_opts = {},
            },

            -- New: Input provider configuration
            input = {
                provider = 'native', -- "native" | "dressing" | "snacks"
                provider_opts = {},
            },

            suggestion = {
                debounce = 600, -- Updated from 100 to 600
                throttle = 600, -- Updated from 100 to 600
            },
        },

        build = 'make',
        dependencies = {
            'nvim-treesitter/nvim-treesitter',
            'nvim-lua/plenary.nvim',
            'MunifTanjim/nui.nvim',
            --- Optional dependencies
            'hrsh7th/nvim-cmp', -- New: for autocompletion
            'echasnovski/mini.pick', -- New: for file_selector
            'nvim-telescope/telescope.nvim', -- New: for file_selector
            'ibhagwan/fzf-lua', -- New: for file_selector
            'stevearc/dressing.nvim', -- New: for input provider
            'folke/snacks.nvim', -- New: for input provider
            'nvim-tree/nvim-web-devicons',
            'zbirenbaum/copilot.lua',
            {
                'HakonHarnes/img-clip.nvim',
                event = 'VeryLazy',
                opts = {
                    default = {
                        embed_image_as_base64 = false,
                        prompt_for_file_name = false,
                        drag_and_drop = {
                            insert_mode = true,
                        },
                        use_absolute_path = true,
                    },
                },
            },
            {
                'MeanderingProgrammer/render-markdown.nvim',
                opts = {
                    file_types = { 'markdown', 'Avante' }, -- Updated to include markdown
                },
                ft = { 'markdown', 'Avante' },
            },
        },
    },
}
