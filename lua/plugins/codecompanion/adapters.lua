return {

    acp = {
        opts = { show_presets = false },
        -- -- Claude Code - via OAuth or API key
        -- claude_code = function()
        --     return require('codecompanion.adapters').extend('claude_code', {
        --         env = {
        --             -- Uses CLAUDE_CODE_OAUTH_TOKEN or ANTHROPIC_API_KEY from enivironment
        --             CLAUDE_CODE_OAUTH_TOKEN = 'cmd:cat '
        --                 .. _G.get_config_dir()
        --                 .. '/claude.key',
        --             -- ANTHROPIC_API_KEY = "cmd:cat " .. _G.get_config_dir() .. "/anthropic.key",
        --         },
        --     })
        -- end,
        -- -- Gemini CLI - via OAuth or API key
        -- gemini_cli = function()
        --     return require('codecompanion.adapters').extend('gemini_cli', {
        --         defaults = {
        --             auth_method = 'gemini-api-key', -- or "oauth-personal", "vertex-ai"
        --         },
        --         env = {
        --             GEMINI_API_KEY = 'cmd:cat '
        --                 .. _G.get_config_dir()
        --                 .. '/google.key',
        --         },
        --     })
        -- end,
        -- -- Codex (OpenAI) - via API key or ChatGPT autgah
        -- codex = function()
        --     return require('codecompanion.adapters').extend('codex', {
        --         defaults = {
        --             auth_method = 'chatgpt', -- or "codex-api-key", "openai-api-key"
        --         },
        --         env = {
        --             OPENAI_API_KEY = 'cmd:cat '
        --                 .. _G.get_config_dir()
        --                 .. '/openai.key',
        --         },
        --     })
        -- end,
        -- OpenCode - configure default model in ~/.config/opencode/config.json
        opencode_acp = function()
            return require('codecompanion.adapters').extend('opencode', {})
        end,
    },
    http = {
        opencode_gpt = function()
            local adapter =
                require('codecompanion.adapters').extend('openai_responses', {
                    name = 'opencode_gpt',
                    url = '${url}${chat_url}',
                    env = {
                        url = 'https://opencode.ai/zen',
                        api_key = 'OPENCODE_API_KEY',
                        chat_url = '/v1/responses',
                    },
                    schema = {
                        model = {
                            default = 'gpt-5.1-codex',
                            choices = {
                                ['gpt-5.2'] = {
                                    formatted_name = 'GPT 5.2',
                                    opts = {
                                        has_function_calling = true,
                                        has_vision = true,
                                        can_reason = true,
                                    },
                                },
                                ['gpt-5.1'] = {
                                    formatted_name = 'GPT 5.1',
                                    opts = {
                                        has_function_calling = true,
                                        has_vision = true,
                                        can_reason = true,
                                    },
                                },
                                ['gpt-5.1-codex'] = {
                                    formatted_name = 'GPT 5.1 Codex',
                                    opts = {
                                        has_function_calling = true,
                                        has_vision = true,
                                        can_reason = true,
                                    },
                                },
                                ['gpt-5.1-codex-max'] = {
                                    formatted_name = 'GPT 5.1 Codex Max',
                                    opts = {
                                        has_function_calling = true,
                                        has_vision = true,
                                        can_reason = true,
                                    },
                                },
                                ['gpt-5.1-codex-mini'] = {
                                    formatted_name = 'GPT 5.1 Codex Mini',
                                    opts = {
                                        has_function_calling = true,
                                        has_vision = true,
                                        can_reason = true,
                                    },
                                },
                            },
                        },
                    },
                })

            -- Add backwards compatibility shims for extensions
            adapter.handlers.chat_output = function(self, data, tools)
                return adapter.handlers.response.parse_chat(self, data, tools)
            end
            adapter.handlers.inline_output = function(self, data, context)
                return adapter.handlers.response.parse_inline(
                    self,
                    data,
                    context
                )
            end
            adapter.handlers.tokens = function(self, data)
                return adapter.handlers.response.parse_tokens(self, data)
            end
            adapter.handlers.form_parameters = function(self, params, messages)
                return adapter.handlers.request.build_parameters(
                    self,
                    params,
                    messages
                )
            end
            adapter.handlers.form_messages = function(self, messages)
                return adapter.handlers.request.build_messages(self, messages)
            end
            adapter.handlers.setup = function(self)
                return adapter.handlers.lifecycle.setup(self)
            end
            adapter.handlers.on_exit = function(self, data)
                return adapter.handlers.lifecycle.on_exit(self, data)
            end

            return adapter
        end,

        opencode_claude = function()
            return require('codecompanion.adapters').extend('anthropic', {
                name = 'opencode_claude',
                url = 'https://opencode.ai/zen/v1/messages',
                env = {
                    api_key = 'OPENCODE_API_KEY',
                },
                schema = {
                    model = {
                        default = 'claude-sonnet-4-5',
                        choices = {
                            'claude-sonnet-4-5',
                            'claude-sonnet-4',
                            'claude-haiku-4-5',
                            'claude-opus-4-5',
                        },
                    },
                },
            })
        end,

        -- Gemini models (Google-compatible endpoint)
        opencode_gemini = function()
            return require('codecompanion.adapters').extend(
                'openai_compatible',
                {
                    name = 'opencode_gemini',
                    env = {
                        url = 'https://opencode.ai/zen/v1',
                        api_key = 'OPENCODE_API_KEY',
                        chat_url = '/models', -- Gemini uses /models
                    },
                    schema = {
                        model = {
                            default = 'gemini-3-flash',
                            choices = {
                                'gemini-3-pro',
                                'gemini-3-flash',
                            },
                        },
                    },
                }
            )
        end,

        -- Other models (standard chat completions)
        opencode_other = function()
            return require('codecompanion.adapters').extend(
                'openai_compatible',
                {
                    name = 'opencode_other',
                    env = {
                        url = 'https://opencode.ai/zen/v1',
                        api_key = 'OPENCODE_API_KEY',
                        chat_url = '/chat/completions',
                    },
                    schema = {
                        model = {
                            default = 'qwen3-coder',
                            choices = {
                                'glm-4.6',
                                'glm-4.7-free',
                                'kimi-k2',
                                'kimi-k2-thinking',
                                'qwen3-coder',
                                'grok-code',
                                'big-pickle',
                            },
                        },
                    },
                }
            )
        end,
        openrouter = function()
            return require('codecompanion.adapters').extend(
                'openai_compatible',
                {
                    name = 'openrouter',
                    env = {
                        url = 'https://openrouter.ai/api',
                        api_key = 'OPENROUTER_API_KEY',
                        chat_url = '/v1/chat/completions',
                    },
                    schema = {
                        model = {
                            default = vim.g.codecompanion_initial_openrouter_model,
                            choices = {
                                -- Reasoning Models
                                ['openai/gpt-5.1-codex-max'] = {
                                    opts = {
                                        can_reason = true,
                                        has_vision = true,
                                    },
                                },
                                ['openai/gpt-5.1-codex-mini'] = {
                                    opts = {
                                        can_reason = true,
                                        has_vision = true,
                                    },
                                },
                                ['openai/gpt-5-mini'] = {
                                    opts = {
                                        can_reason = true,
                                        has_vision = true,
                                    },
                                },
                                ['openai/gpt-5.2'] = {
                                    opts = {
                                        can_reason = true,
                                        has_vision = true,
                                    },
                                },
                                ['openai/o3-mini-high'] = {
                                    opts = {
                                        can_reason = true,
                                        has_vision = true,
                                    },
                                },
                                -- Google Models
                                ['google/gemini-3-flash-preview'] = {
                                    opts = {
                                        can_reason = true,
                                        has_vision = true,
                                    },
                                },
                                ['google/gemini-3-pro-preview'] = {
                                    opts = {
                                        can_reason = true,
                                        has_vision = true,
                                    },
                                },
                                ['google/gemini-2.5-flash-lite'] = {
                                    opts = { has_vision = true },
                                },
                                ['google/gemini-3.5-pro'] = {
                                    opts = { has_vision = true },
                                },
                                -- Anthropic Models
                                ['anthropic/claude-opus-4.5'] = {
                                    opts = {
                                        can_reason = true,
                                        has_vision = true,
                                    },
                                },
                                ['anthropic/claude-sonnet-4.5'] = {
                                    opts = {
                                        can_reason = true,
                                        has_vision = true,
                                    },
                                },
                                -- DeepSeek Models
                                ['deepseek/deepseek-r1'] = {
                                    opts = {
                                        can_reason = true,
                                        has_vision = true,
                                    },
                                },
                                ['deepseek/deepseek-chat'] = {
                                    opts = { has_vision = true },
                                },
                                -- xAI Models
                                ['x-ai/grok-code-fast-1'] = {
                                    opts = {
                                        can_reason = true,
                                        has_vision = true,
                                    },
                                },
                                -- OpenAI Models
                                ['openai/gpt-4-turbo'] = {
                                    opts = { has_vision = true },
                                },
                            },
                        },
                    },
                    handlers = {
                        -- Support for reasoning output (DeepSeek R1, etc.)
                        parse_message_meta = function(self, data)
                            local extra = data.extra
                            if extra and extra.reasoning then
                                data.output.reasoning =
                                    { content = extra.reasoning }
                                if data.output.content == '' then
                                    data.output.content = nil
                                end
                            end
                            return data
                        end,
                    },
                }
            )
        end,

        -- ========================================================
        -- ALTERNATIVE ADAPTERS (Optional)
        -- ========================================================

        -- Anthropic Direct
        claude_sonnet = function()
            return require('codecompanion.adapters').extend('anthropic', {
                name = 'claude_sonnet',
                env = { api_key = 'ANTHROPIC_API_KEY' },
                schema = {
                    model = {
                        default = 'claude-3-5-sonnet-20241022',
                    },
                    max_tokens = { default = 8192 },
                },
            })
        end,

        -- Copilot
        copilot = function()
            return require('codecompanion.adapters').extend('copilot', {
                schema = {
                    model = {
                        default = 'claude-sonnet-4.5',
                    },
                },
            })
        end,

        copilot_gpt = function()
            return require('codecompanion.adapters').extend('copilot', {
                schema = { model = { default = 'gpt-5-mini' } },
            })
        end,

        -- Ollama Local
        qwen_coder_32b = function()
            return require('codecompanion.adapters').extend('ollama', {
                name = 'qwen_coder_32b',
                env = { url = 'http://localhost:11434' },
                schema = {
                    model = { default = 'qwen2.5-coder:32b' },
                    num_ctx = { default = 32768 },
                },
            })
        end,
    },
}
