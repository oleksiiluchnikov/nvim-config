local function stop(count, from, to, index)
    local colors = require('gradient').from_stops(count, from, to)
    return colors and colors[index]
end

local function palette()
    local black = '#2c2925'
    local text = '#a59081'
    local yellow = '#f0a44b'
    local red = '#e1291f'
    local pink = '#e24da1'
    local peach = '#e04d24'
    local green = '#a9983e'
    local sky = '#fbe9e2'
    local mauve = '#91933f'
    local lavender = '#c28d3b'

    return {
        black = black,
        red = red,
        pink = pink,
        blue = stop(8, '#3061a6', '#b9b952', 2),
        peach = peach,
        maroon = '#BD6F3E',
        yellow = yellow,
        green = green,
        sky = sky,
        sapphire = '#89B482',
        mauve = mauve,
        lavender = lavender,
        text = text,
        subtext1 = '#BDAE8B',
        subtext0 = '#A69372',
        overlay2 = '#8C7A58',
        overlay1 = '#735F3F',
        overlay0 = '#958272',
        surface2 = '#1f2121',
        surface1 = '#171819',
        surface0 = '#0e0f10',
        base = '#000000',
        mantle = '#000000',
        crust = '#1E1F1F',
        light_blue = '#4087f5',
    }
end

local function highlights(colors)
    local latte = require('catppuccin.palettes').get_palette('latte')

    local fg_comment = stop(11, colors.black, colors.text, 6)
    local fg_comment_documentation = stop(6, fg_comment, colors.green, 3)
    local fg_conditional = stop(8, colors.yellow, colors.red, 3)
    local fg_diagnostic_unnecessary = stop(8, colors.text, colors.surface0, 6)
    local fg_number = stop(8, colors.yellow, colors.pink, 7)
    local fg_parameter = stop(6, colors.red, fg_comment, 3)
    local fg_typmod_keyword_documentation = stop(
        8,
        stop(9, colors.sky, colors.peach, 8),
        colors.black,
        5
    )
    local fg_type_type_lua = stop(10, colors.yellow, colors.black, 6)

    local function_gradient = require('gradient').from_stops(
        16,
        colors.yellow,
        colors.light_blue
    )
    if not function_gradient then
        return {}
    end

    local fg_function_call = function_gradient[12]
    local fg_function_builtin = stop(6, fg_function_call, colors.pink, 5)
    local fg_property = colors.lavender
    local fg_variable_builtin = stop(5, fg_function_builtin, fg_property, 2)
    local fg_repeat = stop(8, fg_conditional, fg_number, 6)
    local fg_keyword_operator = stop(8, fg_conditional, colors.red, 6)
    local fg_macro = stop(8, colors.mauve, colors.pink, 6)
    local fg_character = stop(8, colors.pink, '#FFFFFF', 5)
    local fg_copilot_annotation = stop(8, fg_comment, colors.mauve, 5)

    return {
        Boolean = { fg = fg_number },
        Character = { fg = fg_character },
        Comment = { fg = fg_comment },
        Conditional = { fg = fg_conditional },
        CopilotAnnotation = { fg = fg_copilot_annotation },
        DiagnosticUnnecessary = { fg = fg_diagnostic_unnecessary },
        FloatBorder = { fg = colors.lavender },
        Function = { fg = fg_function_call },
        Keyword = { fg = colors.mauve },
        LspInlayHint = { fg = '#2a5175', bg = 'NONE' },
        Macro = { fg = fg_macro },
        Number = { fg = fg_number },
        Repeat = { fg = fg_repeat },

        ['@comment.documentation'] = { fg = fg_comment_documentation },
        ['@function.builtin'] = { fg = fg_function_builtin },
        ['@function.call'] = { fg = fg_function_call },
        ['@keyword.operator'] = { fg = fg_keyword_operator },
        ['@keyword.return'] = { fg = fg_conditional },
        ['@lsp.type.function.call.c'] = { fg = fg_function_call },
        ['@lsp.type.keyword.lua'] = { fg = fg_typmod_keyword_documentation },
        ['@lsp.type.type.lua'] = { fg = fg_type_type_lua },
        ['@lsp.typemod.keyword.controlFlow.rust'] = { fg = fg_conditional },
        ['@parameter'] = { fg = fg_parameter },
        ['@property'] = { fg = fg_property },
        ['@typmod.keyword.documentation'] = { fg = fg_typmod_keyword_documentation },
        ['@variable.builtin'] = { fg = fg_variable_builtin },

        IlluminatedWordRead = { bg = '#263341' },
        IlluminatedWordWrite = { bg = latte.flamingo },
        IlluminatedWordCurWord = { fg = '#ffe8e8', bg = latte.flamingo },
        CmpSelection = { bg = '#26336c' },
    }
end

local function setup()
    local catppuccin = require('catppuccin')
    local colors = palette()

    catppuccin.setup({
        background = {
            light = 'latte',
            dark = 'mocha',
        },
        color_overrides = {
            mocha = {
                blue = colors.blue,
                peach = colors.peach,
                maroon = colors.maroon,
                red = colors.red,
                yellow = colors.yellow,
                green = colors.green,
                sky = colors.sky,
                sapphire = colors.sapphire,
                mauve = colors.mauve,
                lavender = colors.lavender,
                text = colors.text,
                subtext1 = colors.subtext1,
                subtext0 = colors.subtext0,
                overlay2 = colors.overlay2,
                overlay1 = colors.overlay1,
                overlay0 = colors.overlay0,
                surface2 = colors.surface2,
                surface1 = colors.surface1,
                surface0 = colors.surface0,
                base = colors.base,
                mantle = colors.mantle,
                crust = colors.crust,
            },
        },
        custom_highlights = highlights(colors),
        integrations = {
            harpoon = true,
            cmp = true,
            markdown = true,
            telescope = { enabled = true },
        },
        styles = {
            comments = { 'italic' },
            conditionals = {},
            loops = {},
            functions = {},
            keywords = {},
            strings = {},
            variables = {},
            numbers = {},
            booleans = {},
            properties = {},
            types = {},
            operators = {},
        },
        transparent_background = false,
        show_end_of_buffer = true,
    })

    if catppuccin.compile then
        catppuccin.compile()
    end

    vim.cmd.colorscheme('catppuccin')
end

return {
    {
        'catppuccin/nvim',
        name = 'catppuccin',
        dependencies = { 'oleksiiluchnikov/gradient.nvim' },
        priority = 1000,
        lazy = false,
        config = setup,
        keys = {
            {
                '<leader>uC',
                function()
                    require('lazy.core.loader').reload('catppuccin')
                    setup()
                end,
                desc = 'Reload Catppuccin',
            },
        },
    },
}
