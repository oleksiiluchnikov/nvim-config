-- [wtf.nvim](https://github.com/piersolenski/wtf.nvim)
-- A Neovim plugin that provides an explaining diagnostic popup using the OpenAI API.
-----------------------------------------------------------------------
return {
    {

        'piersolenski/wtf.nvim',
        dependencies = {
            'MunifTanjim/nui.nvim',
        },
        opts = {
            -- Default AI popup type
            popup_type = 'popup',
            -- An alternative way to set your API key
            provider = 'copilot',
            -- Set your preferred language for the response
            language = 'english',
            -- Any additional instructions
            additional_instructions = 'NO YAPPING! As a Neovim connoisseur with a vast range of expertise, provide me with an unexpected tip—be it basic, advanced, or entirely unconventional—that can surprise both beginners and seasoned users alike. Start your response with "Neovim Insight:" and keep it concise yet impactful.',
            -- Default search engine, can be overridden by passing an option to WtfSeatch
            search_engine = 'google',
            -- Callbacks
            hooks = {
                request_started = nil,
                request_finished = nil,
            },
            -- Add custom colours
            winhighlight = 'Normal:Normal,FloatBorder:FloatBorder',
        },
    },
}
