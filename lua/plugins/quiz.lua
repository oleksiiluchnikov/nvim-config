return {
    {
        dir = '~/projects/quiz.nvim',
        dev = true,
        dependencies = {
            'MunifTanjim/nui.nvim',
        },
        cmd = {
            'QuizOpen',
            'QuizDemo',
            'QuizSubmit',
            'QuizCancel',
        },
        keys = {
            {
                '<leader>uq',
                function()
                    require('quiz').demo()
                end,
                desc = 'open quiz demo',
            },
        },
        opts = {},
        config = function(_, opts)
            require('quiz').setup(opts)
        end,
    },
}
