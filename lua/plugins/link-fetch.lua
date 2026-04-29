return {
    {
        dir = '~/projects/link-fetch.nvim',
        dev = true,
        cmd = {
            'LinkFetchReplace',
            'LinkFetchReplaceTitle',
            'LinkFetchRaycast',
        },
        keys = {
            {
                'g@',
                function()
                    return require('link-fetch').operator({
                        link_text_mode = 'query',
                    })
                end,
                mode = 'n',
                expr = true,
                desc = 'Replace motion with first Google result',
            },
            {
                'g@',
                function()
                    require('link-fetch').replace_visual_selection({
                        link_text_mode = 'query',
                    })
                end,
                mode = 'x',
                desc = 'Replace selection with first Google result',
            },
            {
                'g!',
                function()
                    return require('link-fetch').operator({
                        link_text_mode = 'title',
                    })
                end,
                mode = 'n',
                expr = true,
                desc = 'Replace motion with titled first-result link',
            },
            {
                'g!',
                function()
                    require('link-fetch').replace_visual_selection({
                        link_text_mode = 'title',
                    })
                end,
                mode = 'x',
                desc = 'Replace selection with titled first-result link',
            },
            {
                '<leader>og',
                function()
                    require('link-fetch').open_in_raycast()
                end,
                mode = 'n',
                desc = 'Open Raycast first-result command for word',
            },
            {
                '<leader>og',
                function()
                    require('link-fetch').open_visual_in_raycast()
                end,
                mode = 'x',
                desc = 'Open Raycast first-result command for selection',
            },
        },
        opts = {
            script_path = vim.fn.expand('~/.local/bin/web-open-first-google-result'),
            raycast_command = 'open-first-google-result',
            title_fetch_timeout_ms = 10000,
            markdown_filetypes = {
                markdown = true,
                mdx = true,
                quarto = true,
            },
        },
        config = function(_, opts)
            require('link-fetch').setup(opts)
        end,
    },
}
