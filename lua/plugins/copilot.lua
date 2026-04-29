return {
    {
        'Exafunction/windsurf.nvim',
        event = 'InsertEnter',
        dependencies = {
            'nvim-lua/plenary.nvim',
        },
        config = function()
            require('codeium').setup({
                enable_cmp_source = false,
                virtual_text = {
                    enabled = true,
                    idle_delay = 50,
                    virtual_text_priority = 65535,
                    -- Disable default keybindings — we use config/ai.lua
                    -- with <C-y> (word), <C-j> (full), <C-l> (line)
                    map_keys = false,
                },
            })
        end,
    },
}
