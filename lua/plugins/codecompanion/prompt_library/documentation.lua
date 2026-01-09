-- lua/plugins/codecompanion/prompt_library/documentation.lua
-- Documentation-related prompts

return {
    ['Document Code'] = {
        strategy = 'chat',
        description = 'Generate documentation for selected code',
        opts = {
            index = 40,
            short_name = 'doc',
            modes = { 'v' },
            auto_submit = true,
        },
        prompts = {
            {
                role = 'system',
                content = function(context)
                    return string.format(
                        'Generate comprehensive documentation for %s code including function signatures, parameters, return values, examples, and usage notes.',
                        context.filetype
                    )
                end,
            },
            {
                role = 'user',
                content = function(context)
                    local text = require('codecompanion.helpers.actions').get_code(
                        context.start_line,
                        context.end_line
                    )
                    return string.format(
                        'Document this code:\n\n```%s\n%s\n```',
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

    ['Generate README'] = {
        strategy = 'chat',
        description = 'Generate a comprehensive README for the project',
        opts = {
            index = 41,
            short_name = 'readme',
            auto_submit = false,
        },
        prompts = {
            {
                role = 'system',
                content = [[Generate a comprehensive README.md that includes:
- Project title and description
- Features
- Installation instructions
- Usage examples
- API documentation (if applicable)
- Contributing guidelines
- License information]],
            },
            {
                role = 'user',
                content = 'Generate a README for this project. Ask me questions about the project if needed.',
            },
        },
    },
}

