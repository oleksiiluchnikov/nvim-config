return {
    {
        'oleksiiluchnikov/telescope-prompts.nvim',
        dir = '~/projects/telescope-prompts.nvim',
        dependencies = {
            'nvim-telescope/telescope.nvim',
            'yetone/avante.nvim',
        },
        config = function()
            require('telescope').setup({
                extensions = {
                    prompts = {
                        previewer = true,
                        prompt_title = 'AI Prompts',
                        dirs = { '~/prompts' },
                        file_extensions = { 'md', 'txt' },
                        accept_all_files = true,
                        sort_by = 'name',
                        command = function(text)
                            require('avante.api').ask({ question = text })
                        end,
                    },
                },
            })
            require('telescope').load_extension('prompts')
        end,
        keys = {
            {
                '<leader>am',
                function()
                    require('telescope').extensions.prompts.prompts()
                end,
                desc = 'Open AI Prompts',
            },
        },
    },
}
