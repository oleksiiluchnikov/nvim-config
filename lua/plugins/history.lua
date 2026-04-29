return {
    'lukeb06/history.nvim',
    dependencies = {
        'MunifTanjim/nui.nvim',
        'nvim-tree/nvim-web-devicons', -- optional
    },
    config = true,
    opts = {
        forward_key = '<leader>bh', -- History menu; keep Tab free for normal editor behavior.
        backward_key = '<leader>bH', -- Reverse cycling inside the history UI.
        width = '40%', -- (default) width of the UI, can be a percentage or a number.
        height = '60%', -- (default) height of the UI, can be a percentage or a number.
        persist = true, -- (default) whether to persist the UI across sessions. (this is per directory)
        icons = {
            enable = false,
            custom = { -- Add custom icons for filetypes
                -- lua = "",
                -- markdown = "",
            },
        },
    },
}
