-- https://github.com/npxbr/glow.nvim
return {
    {
        -- Glow markdown preview
        -----------------------------------------------------------------------
        'npxbr/glow.nvim',
        config = function()
            local plugin = 'glow'
            local is_installed, glow = pcall(require, plugin)
            if not is_installed or not glow then
                return
            end

            local glow_path = os.getenv('HOMEBREW_PREFIX')
                    and (os.getenv('HOMEBREW_PREFIX') .. '/bin/glow')
                or 'glow'

            local defaults_opts = {
                glow_path = glow_path,
                install_path = glow_path,
                style = 'dark',
                width = 100,
            }

            glow.setup(defaults_opts)
        end,
    },
}
