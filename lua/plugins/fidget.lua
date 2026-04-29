return {
    {
        'j-hui/fidget.nvim',
        opts = {
            progress = {
                display = {
                    overrides = {
                        vault = {
                            update_hook = function(item)
                                require('fidget.notification').set_content_key(item)
                                item.hidden = true
                            end,
                        },
                    },
                },
            },
        },
    },
}
