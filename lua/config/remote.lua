--[[
    Remote UI Module
    Handles Ghostty window management in remote server mode
--]]

local M = {}

-- Detect server mode
local function is_remote_ui()
    local servername = vim.v.servername
    return servername and servername:match('/tmp/nvim%-server%.sock')
end

-- Function to close the Ghostty window
local function close_ghostty_window()
    -- Try yabai first (fastest)
    local success = os.execute([[
        window_id=$(yabai -m query --windows --window | jq -r '.id')
        [ -n "$window_id" ] && [ "$window_id" != "null" ] && yabai -m window --close "$window_id"
    ]]) == 0

    if not success then
        -- Fallback to AppleScript
        os.execute(
            [[osascript -e 'tell application "System Events" to tell process "Ghostty" to keystroke "w" using command down']]
        )
    end
end

function M.setup()
    if not is_remote_ui() then
        return
    end

    -- Override :q to close window (with proper error handling)
    vim.api.nvim_create_user_command('Q', function()
        -- Try to close window first
        local ok, _ = pcall(function()
            vim.cmd('close')
        end)

        if not ok then
            -- Can't close window (probably last one), try buffer delete
            local buf_count = #vim.fn.getbufinfo({ buflisted = 1 })

            if buf_count > 1 then
                vim.cmd('bdelete')
            else
                -- Last buffer - close the Ghostty window
                vim.notify('Closing window...', vim.log.levels.INFO)
                vim.defer_fn(close_ghostty_window, 50)
            end
        end
    end, { desc = 'Remote: Safe quit (close window or buffer)' })

    -- Commands
    vim.api.nvim_create_user_command(
        'QuitUI',
        close_ghostty_window,
        { desc = 'Remote: Close Ghostty window' }
    )
    vim.api.nvim_create_user_command(
        'QuitServer',
        'confirm qall',
        { desc = 'Remote: Stop Neovim server' }
    )

    -- Remaps
    vim.cmd([[
        cnoreabbrev <expr> q (getcmdtype() == ':' && getcmdline() == 'q') ? 'Q' : 'q'
        cnoreabbrev <expr> quit (getcmdtype() == ':' && getcmdline() == 'quit') ? 'Q' : 'quit'
        cnoreabbrev <expr> wq (getcmdtype() == ':' && getcmdline() == 'wq') ? 'w<bar>Q' : 'wq'
        cnoreabbrev <expr> qa (getcmdtype() == ':' && getcmdline() == 'qa') ? 'Q' : 'qa'
    ]])

    -- ZZ/ZQ
    vim.keymap.set('n', 'ZZ', function()
        vim.cmd('write')
        close_ghostty_window()
    end, { desc = 'Remote: Save and close window' })

    vim.keymap.set('n', 'ZQ', close_ghostty_window, { desc = 'Remote: Close window' })
end

return M
