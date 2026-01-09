return {
    {
        'MeanderingProgrammer/render-markdown.nvim',
        enabled = false, -- Consider disabling this plugin entirely
        opts = {
            file_types = { 'Avante', 'markdown', 'codecompanion' },
            -- Only render in normal mode, not in insert/visual modes
            render_modes = { 'n' },

            -- Disable all the rendering features
            code = { enabled = false },
            heading = { enabled = false },
            bullet = { enabled = false },
            quote = { enabled = false },
            checkbox = { enabled = false },
        },
        ft = { 'Avante', 'markdown', 'codecompanion' },
    },
}
