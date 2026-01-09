return {
    {
        'oleksiiluchnikov/telescope-avante.nvim',
        dir = '~/projects/telescope-avante.nvim',
        dependencies = {
            'nvim-telescope/telescope.nvim',
            'yetone/avante.nvim',
        },
        setup = function()
            require('telescope').load_extension('avante')
        end,
        keys = {
            { '<leader>ap', '<cmd>Telescope avante<CR>', desc = 'Open Avante' },
        },
    },
}
