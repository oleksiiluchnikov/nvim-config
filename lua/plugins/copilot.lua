return {
    {
        'zbirenbaum/copilot.lua',
        event = 'InsertEnter',
        init = function()
            vim.api.nvim_set_hl(0, 'CopilotSuggestion', { fg = '#ab47bc' })
            vim.api.nvim_set_hl(0, 'AvanteSuggestion', { fg = '#4caf50' })
            vim.api.nvim_set_hl(0, 'CodeCompanionInline', { fg = '#2196f3' })
        end,
        opts = {
            panel = { enabled = false },
            suggestion = {
                enabled = true,
                auto_trigger = true,
                debounce = 50,
            },
            filetypes = { ['*'] = true },
            copilot_node_command = 'node',
            server_opts_overrides = {},
        },
    },
}
