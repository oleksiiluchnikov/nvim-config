local parsers = {
    'bash',
    'c',
    'clojure',
    'comment',
    'css',
    'diff',
    'go',
    'html',
    'javascript',
    'jsdoc',
    'json',
    'jsonc',
    'lua',
    'luadoc',
    'luap',
    'markdown',
    'markdown_inline',
    'printf',
    'python',
    'query',
    'regex',
    'rust',
    'svelte',
    'sxhkdrc',
    'teal',
    'toml',
    'tsx',
    'typescript',
    'vim',
    'vimdoc',
    'xml',
    'yaml',
}

local install_dir = vim.fs.joinpath(vim.fn.stdpath('data'), 'site')
local reported_failures = {}

return {
    {
        -- [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter)
        -- The `main` branch is a rewrite for Neovim nightly/0.12 and no longer
        -- supports the old module-based feature configuration.
        'nvim-treesitter/nvim-treesitter',
        branch = 'main',
        version = false,
        lazy = false,
        init = function()
            vim.opt.rtp:prepend(install_dir)
        end,
        build = function()
            local treesitter = require('nvim-treesitter')
            treesitter.setup({ install_dir = install_dir })
            treesitter.install(parsers, { summary = true }):wait(300000)
            treesitter.update(parsers, { summary = true }):wait(300000)
        end,
        config = function()
            require('nvim-treesitter').setup({ install_dir = install_dir })
            vim.treesitter.language.register('javascript', 'dataviewjs')

            local group = vim.api.nvim_create_augroup(
                'user_treesitter_start',
                { clear = true }
            )
            vim.api.nvim_create_autocmd('FileType', {
                group = group,
                callback = function(args)
                    local filetype = vim.bo[args.buf].filetype
                    if filetype == 'notify' then
                        return
                    end

                    local lang = vim.treesitter.language.get_lang(filetype)
                    if not lang then
                        return
                    end

                    local parser_ok = vim.treesitter.language.add(lang)
                    if not parser_ok then
                        if filetype ~= '' and vim.bo[args.buf].syntax == '' then
                            vim.bo[args.buf].syntax = filetype
                        end
                        return
                    end

                    local active = vim.treesitter.highlighter.active[args.buf]
                    if active then
                        return
                    end

                    local ok, err = pcall(vim.treesitter.start, args.buf, lang)
                    if ok then
                        return
                    end

                    if filetype ~= '' and vim.bo[args.buf].syntax == '' then
                        vim.bo[args.buf].syntax = filetype
                    end

                    local failure_key = string.format('%s:%s', filetype, lang)
                    if reported_failures[failure_key] then
                        return
                    end
                    reported_failures[failure_key] = true

                    vim.schedule(function()
                        vim.notify(
                            string.format(
                                'Treesitter failed for %s (%s): %s',
                                filetype,
                                lang,
                                err
                            ),
                            vim.log.levels.WARN,
                            { title = 'nvim-treesitter' }
                        )
                    end)
                end,
            })
        end,
    },
}
