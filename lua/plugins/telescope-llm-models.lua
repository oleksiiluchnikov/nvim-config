return {
    {
        'oleksiiluchnikov/telescope-llm-models.nvim',
        dir = '~/projects/telescope-llm-models.nvim',
        dependencies = {
            'nvim-telescope/telescope.nvim',
            'olimorris/codecompanion.nvim',
        },
        setup = function()
            require('telescope').load_extension('llm_models')
        end,
        keys = {
            {
                '<leader>m',
                '<cmd>Telescope llm_models<CR>',
                desc = 'Open LLM Models',
            },
        },
    },
}
