return {
    {
        'rebelot/kanagawa.nvim',
        opts = {
            compile = false,
            undercurl = true,
            commentStyle = { italic = true },
            functionStyle = {},
            keywordStyle = { italic = true },
            statementStyle = { bold = true },
            typeStyle = {},
            transparent = false,
            dimInactive = true,
            terminalColors = true,
            colors = {
                palette = {},
                theme = {
                    wave = {},
                    lotus = {},
                    dragon = {},
                    all = {},
                },
            },
            ---@diagnostic disable-next-line: unused-local
            overrides = function(colors)
                return {}
            end,
            theme = 'wave',
            background = {
                dark = 'wave',
                light = 'lotus',
            },
        },
    },
}
