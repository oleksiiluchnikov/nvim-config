return {
    {
        'g0t4/ask-openai.nvim',
        enabled = false, -- upstream bug: requires 'devtools.humanize' (author's personal module)

        -- include one of the following:
        -- 1. set opts, empty = defaults
        opts = {},
        -- 2. call setup
        config = function()
            require('ask-openai').setup({})
        end,

        dependencies = { 'nvim-lua/plenary.nvim' },

        event = { 'CmdlineEnter' }, -- optional, for startup speed
        -- FYI most of the initial performance hit doesn't happen until the first use
    },
}
