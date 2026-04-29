--[[
    Remote UI Module
    Handles Ghostty window management in remote server mode
--]]


-- Detect that we are the --remote-ui CLIENT attached to the nvim-server socket,
-- NOT the headless server itself.
--
-- Headless server:  vim.v.servername == "/tmp/nvim-server.sock"
--                   #vim.api.nvim_list_uis() == 0  (no UI yet at init time)
-- remote-ui client: vim.v.servername == ""  (client has no server name)
--                   $NVIM env var points to the socket it connected to
--
-- We check NVIM env var: it is set by the --server flag to the socket path,
-- and is only present in the --remote-ui client process, not the server.
local function is_remote_ui()
    local nvim_sock = vim.env.NVIM
    return nvim_sock ~= nil
        and nvim_sock ~= ''
        and nvim_sock:match('nvim%-server%.sock') ~= nil
end

-- Function to close the nvim-server Ghostty window (NOT the focused window)
local function close_ghostty_window()
    -- Find the nvim-server window by title, not by focus — avoids killing other Ghostty windows
    local success = os.execute([[
        window_id=$(yabai -m query --windows | jq -r '.[] | select(.app=="Ghostty" and (.title | contains("nvim-server"))) | .id' | head -1)
        [ -n "$window_id" ] && [ "$window_id" != "null" ] && yabai -m window --close "$window_id"
    ]]) == 0

    if not success then
        -- Fallback to AppleScript — target nvim-server window specifically
        os.execute([[osascript -e '
            tell application "System Events"
                tell process "Ghostty"
                    try
                        set nvimWin to first window whose name contains "nvim-server"
                        click button 1 of nvimWin
                    end try
                end tell
            end tell
        ']])
    end
end
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
            -- Last buffer — detach the UI cleanly first (Neovim 0.11+),
            -- then close the specific nvim-server Ghostty window by title.
            -- Order matters: detach first so the server stays alive,
            -- then close the window from the outside by title so we don't
            -- accidentally close other Ghostty windows.
            vim.cmd('detach')
            vim.defer_fn(close_ghostty_window, 50)
        end
    end
end, { desc = 'Remote: Safe quit (close window or buffer)' })

-- Commands
vim.api.nvim_create_user_command('QuitUI', function()
    vim.cmd('detach')
    vim.defer_fn(close_ghostty_window, 50)
end, { desc = 'Remote: Detach UI and close Ghostty window' })
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
    vim.cmd('detach')
    vim.defer_fn(close_ghostty_window, 50)
end, { desc = 'Remote: Save and close window' })

vim.keymap.set('n', 'ZQ', function()
    vim.cmd('detach')
    vim.defer_fn(close_ghostty_window, 50)
end, { desc = 'Remote: Close window without saving' })
