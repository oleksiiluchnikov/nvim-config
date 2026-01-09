return {
    {
        'oleksiiluchnikov/server-title.nvim',
        dir = '~/projects/server-title.nvim',
        opts = {
            show = {
                cwd = true,
                git_branch = true,
                file_count = true,
                modified_count = true,
                lsp_status = true,
            },
            update_on = {
                dir_changed = true,
                buf_enter = true,
                buf_write = true,
                lsp_attach = true,
            },
            separator = ' | ',
            git_icon = '', -- Nerd font git icon
        },
    },
}
