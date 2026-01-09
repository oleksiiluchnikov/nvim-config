return {
    {
        -- [lazydev](https://github.com/folke/lazydev.nvim)
        -- `lazydev` configures Lua LSP for your Neovim config, runtime and plugins
        -- used for completion, annotations and signatures of Neovim apis
        'folke/lazydev.nvim',
        ft = 'lua',
        opts = {
            debug = false,
            library = {
                { path = 'luvit-meta/library', words = { 'vim%.uv' } },
                { path = 'wezterm-types', mods = { 'wezterm' } },
                { path = 'luassert-types/library', words = { 'assert' } },
                { path = 'busted-types/library', words = { 'describe' } },
            },
        },
    },
}
