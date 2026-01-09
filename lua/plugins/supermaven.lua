return {
    {
        -- [supermaven-nvim](https://github.com/supermaven-inc/supermaven-nvim)
        -- AI-powered code completion from [Supermaven](https://supermaven.com)
        -----------------------------------------------------------------------
        'supermaven-inc/supermaven-nvim',
        lazy = false,
        opts = {
            ignore_filetypes = { cpp = true },
            color = {
                suggestion_color = '#00b7f0',
                cterm = 244,
            },
            log_level = 'off',
            disable_inline_completion = false, -- disables inline completion for use with cmp
            disable_keymaps = true, -- disables built in keymaps for more manual control
        },
        event = 'VimEnter',
    },
}
