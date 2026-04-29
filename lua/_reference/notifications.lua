local M = {}

--- Default notification configuration
M.config = {
    sound = 'default', -- 'default', 'glass', 'Hero', 'Ping', 'Pop', 'Purr', 'Submarine', 'Tink', or nil
    icon = nil, -- Path to icon file or app name
    timeout = 5, -- Seconds (terminal-notifier only)
    group = 'nvim', -- Group notifications together
}

--- Send a notification using terminal-notifier or osascript
--- @param title string The notification title
--- @param body string The notification message
--- @param opts? table Optional configuration { sound, icon, timeout, subtitle, group, url, execute }
function M.send_notification(title, body, opts)
    opts = vim.tbl_deep_extend('force', M.config, opts or {})

    -- Escape special characters for shell
    local function escape(str)
        return str:gsub('"', '\\"'):gsub('\'', '\'\\\'\''):gsub('`', '\\`')
    end

    local escaped_title = escape(title)
    local escaped_body = escape(body)

    -- Try terminal-notifier first (more features)
    local has_notifier = vim.fn.executable('terminal-notifier') == 1

    if has_notifier then
        local args = {
            string.format('-title "%s"', escaped_title),
            string.format('-message "%s"', escaped_body),
        }

        -- Add optional parameters
        if opts.subtitle then
            table.insert(
                args,
                string.format('-subtitle "%s"', escape(opts.subtitle))
            )
        end

        if opts.sound then
            table.insert(args, string.format('-sound "%s"', opts.sound))
        end

        if opts.group then
            table.insert(args, string.format('-group "%s"', opts.group))
        end

        if opts.timeout then
            table.insert(args, string.format('-timeout %d', opts.timeout))
        end

        if opts.icon then
            -- Can be path to image or app name
            table.insert(
                args,
                string.format('-appIcon "%s"', escape(opts.icon))
            )
        end

        if opts.contentImage then
            -- Attach an image to the notification
            table.insert(
                args,
                string.format('-contentImage "%s"', escape(opts.contentImage))
            )
        end

        if opts.url then
            -- Open URL when notification is clicked
            table.insert(args, string.format('-open "%s"', escape(opts.url)))
        end

        if opts.execute then
            -- Execute command when notification is clicked
            table.insert(
                args,
                string.format('-execute "%s"', escape(opts.execute))
            )
        end

        if opts.actions then
            -- Add action buttons (macOS 10.9+)
            for _, action in ipairs(opts.actions) do
                table.insert(
                    args,
                    string.format('-actions "%s"', escape(action))
                )
            end
        end

        local command = 'terminal-notifier ' .. table.concat(args, ' ')
        vim.fn.system(command)
    else
        -- Fallback to osascript (limited features)
        local script = string.format(
            'display notification "%s" with title "%s"',
            escaped_body,
            escaped_title
        )

        if opts.subtitle then
            script = script
                .. string.format(' subtitle "%s"', escape(opts.subtitle))
        end

        if opts.sound then
            script = script .. string.format(' sound name "%s"', opts.sound)
        end

        local command = string.format('osascript -e \'%s\'', script)
        vim.fn.system(command)
    end
end

--- Send a success notification (with green checkmark)
--- @param title string
--- @param body string
--- @param opts? table
function M.success(title, body, opts)
    opts = vim.tbl_deep_extend('force', {
        sound = 'Glass',
        subtitle = '✅ Success',
    }, opts or {})
    M.send_notification(title, body, opts)
end

--- Send an error notification (with red X)
--- @param title string
--- @param body string
--- @param opts? table
function M.error(title, body, opts)
    opts = vim.tbl_deep_extend('force', {
        sound = 'Basso',
        subtitle = '❌ Error',
    }, opts or {})
    M.send_notification(title, body, opts)
end

--- Send a warning notification (with yellow warning sign)
--- @param title string
--- @param body string
--- @param opts? table
function M.warn(title, body, opts)
    opts = vim.tbl_deep_extend('force', {
        sound = 'Tink',
        subtitle = '⚠️  Warning',
    }, opts or {})
    M.send_notification(title, body, opts)
end

--- Send an info notification (with blue info icon)
--- @param title string
--- @param body string
--- @param opts? table
function M.info(title, body, opts)
    opts = vim.tbl_deep_extend('force', {
        sound = 'Pop',
        subtitle = 'ℹ️  Info',
    }, opts or {})
    M.send_notification(title, body, opts)
end

--- Send a notification with a progress indicator
--- @param title string
--- @param body string
--- @param percent number Progress percentage (0-100)
--- @param opts? table
function M.progress(title, body, percent, opts)
    local bar_length = 10
    local filled = math.floor(percent / 100 * bar_length)
    local empty = bar_length - filled
    local progress_bar = string.rep('█', filled) .. string.rep('░', empty)

    local message = string.format('%s\n%s %d%%', body, progress_bar, percent)

    opts = vim.tbl_deep_extend('force', {
        sound = nil, -- No sound for progress updates
        subtitle = 'In Progress',
    }, opts or {})

    M.send_notification(title, message, opts)
end

--- Send a notification when a long-running task completes
--- @param task_name string Name of the completed task
--- @param duration? number Duration in seconds
--- @param opts? table
function M.task_complete(task_name, duration, opts)
    local body = duration and string.format('Completed in %.1fs', duration)
        or 'Task completed'

    opts = vim.tbl_deep_extend('force', {
        sound = 'Glass',
        subtitle = '✅ ' .. task_name,
    }, opts or {})

    M.send_notification('Neovim', body, opts)
end

--- Test all notification types
function M.test()
    M.success('Test Success', 'This is a success notification')
    vim.defer_fn(function()
        M.error('Test Error', 'This is an error notification')
    end, 1000)
    vim.defer_fn(function()
        M.warn('Test Warning', 'This is a warning notification')
    end, 2000)
    vim.defer_fn(function()
        M.info('Test Info', 'This is an info notification')
    end, 3000)
    vim.defer_fn(function()
        M.progress('Test Progress', 'Processing...', 75)
    end, 4000)
    vim.defer_fn(function()
        M.task_complete('Test Task', 5.3)
    end, 5000)
end

--- Setup function to configure defaults
--- @param opts table Configuration options
function M.setup(opts)
    M.config = vim.tbl_deep_extend('force', M.config, opts or {})
end

return M
