return {
    {
        'folke/Trouble.nvim',
        cmd = 'Trouble',
        config = function()
            -- LSP Diagnostics Options Setup
            local sign = function(opts)
                vim.fn.sign_define(opts.name, {
                    texthl = opts.name,
                    text = opts.text,
                    numhl = '',
                })
            end
            sign({ name = 'DiagnosticSignError', text = '' })
            sign({ name = 'DiagnosticSignWarn', text = '' })
            sign({ name = 'DiagnosticSignHint', text = '' })
            sign({ name = 'DiagnosticSignInfo', text = '' })

            --- @type vim.diagnostic.Opts
            local default_opts = {
                signs = {
                    -- Icons / text used for a diagnostic
                    error = '',
                    warning = '',
                    hint = '',
                    information = '',
                    other = '﫠',
                },
                update_in_insert = true, -- update diagnostics insert mode
                underline = true, -- show underline diagnostics (default: true)
                virtual_text = {
                    prefix = ' ',
                    spacing = 80,
                },
                severity_sort = {
                    reverse = false, -- reverse the sort order (default: false)
                },
                float = {
                    border = 'single', -- border style (default: "single")
                    -- source = 'always', – show source (default: "always")
                    source = true,
                    width = 100, -- width of the output (default: 80)
                    height = 60, -- height of the output (default: 20)
                    focusable = true,
                    wrap = true, -- wrap the lines (default: true)
                },
            }
            vim.diagnostic.config(default_opts)

            -- Trouble(https://github.com/folke/trouble.nvim)
            --- @type trouble.Config
            local opts = {
                position = 'right', -- position of the list can be: bottom, top, left, right
                height = 10, -- height of the trouble list when position is top or bottom
                width = 50, -- width of the list when position is left or right
                -- icons = true, -- use devicons for filenames
                mode = 'workspace_diagnostics', -- "workspace_diagnostics", "document_diagnostics", "quickfix", "lsp_references", "loclist"
                severity = nil, -- nil (ALL) or vim.diagnostic.severity.ERROR | WARN | INFO | HINT
                fold_open = '', -- icon used for open folds
                fold_closed = '', -- icon used for closed folds
                group = true, -- group results by file
                padding = true, -- add an extra new line on top of the list
                cycle_results = true, -- cycle item list when reaching beginning or end of list
                action_keys = { -- key mappings for actions in the trouble list
                    -- map to {} to remove a mapping, for example:
                    -- close = {},
                    close = 'q', -- close the list
                    cancel = '<esc>', -- cancel the preview and get back to your last window / buffer / cursor
                    refresh = 'r', -- manually refresh
                    jump = { '<cr>', '<tab>', '<2-leftmouse>' }, -- jump to the diagnostic or open / close folds
                    open_split = { '<c-x>' }, -- open buffer in new split
                    open_vsplit = { '<c-v>' }, -- open buffer in new vsplit
                    open_tab = { '<c-t>' }, -- open buffer in new tab
                    jump_close = { 'o' }, -- jump to the diagnostic and close the list
                    toggle_mode = 'm', -- toggle between "workspace" and "document" diagnostics mode
                    switch_severity = 's', -- switch "diagnostics" severity filter level to HINT / INFO / WARN / ERROR
                    toggle_preview = 'P', -- toggle auto_preview
                    hover = 'K', -- opens a small popup with the full multiline message
                    preview = 'p', -- preview the diagnostic location
                    open_code_href = 'c', -- if present, open a URI with more information about the diagnostic error
                    close_folds = { 'zM', 'zm' }, -- close all folds
                    open_folds = { 'zR', 'zr' }, -- open all folds
                    toggle_fold = { 'zA', 'za' }, -- toggle fold of current file
                    previous = 'k', -- previous item
                    next = 'j', -- next item
                    help = '?', -- help menu
                },
                multiline = true, -- render multi-line messages
                indent_lines = true, -- add an indent guide below the fold icons
                win_config = { border = 'single' }, -- window configuration for floating windows. See |nvim_open_win()|.
                auto_open = false, -- automatically open the list when you have diagnostics
                auto_close = false, -- automatically close the list when you have no diagnostics
                auto_preview = true, -- automatically preview the location of the diagnostic. <esc> to close preview and go back to last window
                auto_fold = false, -- automatically fold a file trouble list at creation
                auto_jump = { 'lsp_definitions' }, -- for the given modes, automatically jump if there is only a single result
                include_declaration = {
                    'lsp_references',
                    'lsp_implementations',
                    'lsp_definitions',
                }, -- for the given modes, include the declaration of the current symbol in the results
                signs = {
                    -- icons / text used for a diagnostic
                    error = '',
                    warning = '',
                    hint = '',
                    information = '',
                    other = '',
                },
                use_diagnostic_signs = true, -- enabling this will use the signs defined in your lsp client
            }
            require('trouble').setup(opts)
        end,
        keys = {
            {
                '<leader>xx',
                '<cmd>Trouble diagnostics toggle<cr>',
                desc = 'Diagnostics (Trouble)',
                noremap = true,
            },
            {
                '<leader>xX',
                '<cmd>Trouble diagnostics toggle filter.buf=0<cr>',
                desc = 'Buffer Diagnostics (Trouble)',
                noremap = true,
            },
            {
                '<leader>cs',
                '<cmd>Trouble symbols toggle focus=false<cr>',
                desc = 'Symbols (Trouble)',
            },
            {
                '<leader>cl',
                '<cmd>Trouble lsp toggle focus=false win.position=right<cr>',
                desc = 'LSP Definitions / references / ... (Trouble)',
            },
            {
                '<leader>xL',
                '<cmd>Trouble loclist toggle<cr>',
                desc = 'Location List (Trouble)',
            },
            {
                '<leader>xQ',
                '<cmd>Trouble qflist toggle<cr>',
                desc = 'Quickfix List (Trouble)',
            },
        },
    },
}
