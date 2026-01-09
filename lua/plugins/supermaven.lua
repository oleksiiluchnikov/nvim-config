return {
    {
        'supermaven-inc/supermaven-nvim',
        event = 'InsertEnter',
        opts = {
            ignore_filetypes = { cpp = true },
            color = {
                suggestion_color = '#ffa726',
                cterm = 178,
            },
            log_level = 'off',
            disable_inline_completion = false,
            disable_keymaps = true,
        },
    },
}
