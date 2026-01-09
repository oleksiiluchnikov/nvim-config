return {
    'L3MON4D3/LuaSnip',
    config = function()
        -- LuaSnip setup
        ------------------------------------------------------------------------------
        if not pcall(require, 'luasnip') then
            return
        end

        local ls = require('luasnip') -- Import the library
        local types = require('luasnip.util.types') -- Import the types table
        ls.setup({
            snip_env = {
                s = function(...)
                    local snip = ls.s(...)
                    -- we can't just access the global `ls_file_snippets`, since it will be
                    -- resolved in the environment of the scope in which it was defined.
                    table.insert(getfenv(2).ls_file_snippets, snip)
                end,
                parse = function(...)
                    local snip = ls.parser.parse_snippet(...)
                    table.insert(getfenv(2).ls_file_snippets, snip)
                end,
                -- remaining definitions.
            },
        })

        -- Config
        ------------------------------------------------------------------------------
        ls.config.set_config({
            history = true, -- Save snippets history
            updateevents = 'TextChanged,TextChangedI', -- Events that update the snippets

            enable_autosnippets = true, -- Enable auto snippets

            -- Crazy highlights!
            ext_opts = {
                [types.choiceNode] = {
                    active = { virt_text = { { 'Choice', 'Comment' } } },
                },
                [types.insertNode] = {
                    active = { virt_text = { { 'Insert', 'Comment' } } },
                },
                [types.functionNode] = {
                    active = { virt_text = { { 'Function', 'Comment' } } },
                },
                [types.snippetNode] = {
                    active = { virt_text = { { 'Snippet', 'Comment' } } },
                },
            },
        })

        --- Load snippets
        require('snippets').init()

        -- Mappings
        ------------------------------------------------------------------------------

        -- <c-k>
        -- will expand the current item or jump to the next one
        vim.keymap.set({ 'i', 's' }, '<C-k>', function()
            if ls.expand_or_jumpable() then
                ls.expand_or_jump()
            end
        end, { silent = true })

        -- <c-j>
        -- will jump to the previous item
        vim.keymap.set({ 'i', 's' }, '<c-j>', function()
            if ls.jumpable(-1) then
                ls.jump(-1)
            end
        end, { silent = true })

        -- <c-l>
        -- is used to selecting within a list of options
        vim.keymap.set({ 'i', 's' }, '<c-l>', function()
            if ls.choice_active() then
                ls.change_choice(1)
            end
        end, { silent = true })

        -- <leader><leader> > s
        -- will source my luasnip file again, which will reload all my snippets
        vim.keymap.set({ 'n', 's' }, '<leader><leader> > s', function()
            vim.cmd('luafile ~/.config/nvim/lua/plugins/luasnip/init.lua')
            vim.notify(
                'Snippets reloaded!',
                vim.log.levels.INFO,
                { title = 'LuaSnip' }
            )
        end, { silent = true })
    end,
}
