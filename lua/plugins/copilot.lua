-- [copilot.lua](https://github.com/zbirenbaum/copilot.lua)
-- Adds core Copilot integration
-----------------------------------------------------------------------
return {
    {
        'zbirenbaum/copilot.lua',
        event = 'VimEnter',
        init = function()
            vim.api.nvim_set_hl(0, 'CopilotSuggestion', { fg = '#408500' })
        end,
        opts = {
            panel = {
                enabled = false,
                auto_refresh = true,
                keymap = {},
                layout = {
                    position = 'right', -- | top | left | right
                    ratio = 0.4,
                },
            },
            suggestion = {
                enabled = true,
                auto_trigger = true,
                debounce = 0,
            },
            -- Allow to be enabled in all filetypes
            filetypes = {
                ['*'] = true,
                -- markdown = function()
                --     -- Disable for markdown files if 'example_contained_name' is in the path (case insensitive)
                --     local filename = vim.fn.expand("%:p")
                --     if filename and type(filename) == "string" then
                --         filename:lower()
                --     end
                --     if filename == "" then
                --         return true
                --     end
                --     local match = string.match(filename, "example_contained_name")
                --     if match then
                --         return false
                --     end
                --     return true
                -- end,
            },
            copilot_node_command = 'node', -- Node.js version must be > 16.x
            server_opts_overrides = {},
        },
        lazy = false,
    },
}
