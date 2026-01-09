return {
    {
        'oleksiiluchnikov/airtable.nvim',
        dir = '~/projects/airtable.nvim',
        lazy = false,
        config = function()
            vim.g.airtable_debug = true
            require('airtable').setup({
                api_key = os.getenv('AIRTABLE_API_KEY'),
                default_base = os.getenv('AIRTABLE_BASE_ID'),
            })
        end,

        keys = {
            {
                '<leader>at',
                function()
                    require('airtable.pickers.table').tables()
                end,
                desc = 'Airtable',
            },
        },
    },
}
