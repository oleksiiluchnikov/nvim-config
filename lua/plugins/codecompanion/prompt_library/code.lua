-- lua/plugins/codecompanion/prompt_library/code.lua
-- Code-related prompts

return {
    ['Code Review'] = {
        strategy = 'chat',
        description = 'Review selected code for improvements',
        opts = {
            index = 30,
            short_name = 'review',
            modes = { 'v' },
            auto_submit = true,
        },
        prompts = {
            {
                role = 'system',
                content = function(context)
                    return string.format(
                        'You are a senior %s developer conducting a code review. Provide constructive feedback on code quality, performance, security, and best practices.',
                        context.filetype
                    )
                end,
                opts = {
                    visible = false,
                },
            },
            {
                role = 'user',
                content = function(context)
                    local text =
                        require('codecompanion.helpers.actions').get_code(
                            context.start_line,
                            context.end_line
                        )
                    return string.format(
                        'Review this %s code:\n\n```%s\n%s\n```\n\nProvide feedback on:\n1. Code quality and readability\n2. Performance concerns\n3. Security issues\n4. Best practices\n5. Suggested improvements',
                        context.filetype,
                        context.filetype,
                        text
                    )
                end,
                opts = {
                    contains_code = true,
                },
            },
        },
    },

    ['Optimize Code'] = {
        strategy = 'chat',
        description = 'Optimize selected code for performance',
        opts = {
            index = 31,
            short_name = 'optimize',
            modes = { 'v' },
            auto_submit = true,
        },
        prompts = {
            {
                role = 'system',
                content = function(context)
                    return string.format(
                        'You are a performance optimization expert for %s. Analyze code and suggest optimizations.',
                        context.filetype
                    )
                end,
            },
            {
                role = 'user',
                content = function(context)
                    local text =
                        require('codecompanion.helpers.actions').get_code(
                            context.start_line,
                            context.end_line
                        )
                    return string.format(
                        'Optimize this code:\n\n```%s\n%s\n```\n\nFocus on:\n- Time complexity\n- Space complexity\n- Algorithmic improvements\n- Language-specific optimizations',
                        context.filetype,
                        text
                    )
                end,
                opts = {
                    contains_code = true,
                },
            },
        },
    },

    ['Add Error Handling'] = {
        strategy = 'chat',
        description = 'Add comprehensive error handling to code',
        opts = {
            index = 32,
            short_name = 'errorhandle',
            modes = { 'v' },
            auto_submit = true,
        },
        prompts = {
            {
                role = 'system',
                content = 'Add robust error handling with proper error messages, logging, and recovery strategies.',
            },
            {
                role = 'user',
                content = function(context)
                    local text =
                        require('codecompanion.helpers.actions').get_code(
                            context.start_line,
                            context.end_line
                        )
                    return string.format(
                        'Add error handling to this code:\n\n```%s\n%s\n```',
                        context.filetype,
                        text
                    )
                end,
                opts = {
                    contains_code = true,
                },
            },
        },
    },
}
