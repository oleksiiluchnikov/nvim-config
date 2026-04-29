return {
    {
        dir = '~/projects/aesthetic.nvim',
        enabled = false,
        dependencies = {
            { dir = '~/projects/gradient.nvim' },
        },
        event = 'VeryLazy',
        opts = {
            enabled = true,
            palette = 'aesthetic',
            background = 'auto',
            workspaces = {
                ['~/knowledge'] = {
                    mode = 'workspace',
                    palette = 'aesthetic',
                    font = 'writing',
                },
            },
            filetypes = {
                markdown = {
                    font = 'writing',
                },
            },
            schedule = {
                enabled = true,
                dawn = { start = '06:00', finish = '07:30' },
                dusk = { start = '19:30', finish = '21:00' },
                interval_sec = 60,
            },
            ghostty = {
                enabled = true,
                config_path = vim.fn.expand('~/.config/ghostty/config'),
                reload_cmd = {
                    'menucli',
                    'click',
                    'Ghostty::Reload Configuration',
                    '--app',
                    'Ghostty',
                    '--all',
                },
                debounce_ms = 200,
                fonts = {
                    writing = 'font/writing',
                    coding = 'font/coding',
                },
                themes = {
                    light = 'aesthetic-light',
                    dark = 'aesthetic-dark',
                },
            },
        },
    },
}
