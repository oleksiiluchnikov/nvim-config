return {

    {
        'rcarriga/nvim-notify',
        ---@type notify.Config
        ---@diagnostic disable-next-line: missing-fields
        opts = {
            fps = 60,
            icons = {
                DEBUG = '',
                ERROR = '',
                INFO = '',
                TRACE = '✎',
                WARN = '',
            },
            level = vim.log.levels.INFO,
            minimum_width = 100,
            top_down = true,
            stages = 'static',
            render = 'default',
            timeout = 3000,
        },
        init = function()
            ---@class plugins.nvim-notify.notify.Options
            --- Custom options for an individual notification
            ---@field title? string
            ---@field icon? string
            ---@field timeout? number|boolean Time to show notification in milliseconds, set to false to disable timeout.
            ---@field on_open? function Callback for when window opens, receives window as argument.
            ---@field on_close? function Callback for when window closes, receives window as argument.
            ---@field keep? function Function to keep the notification window open after timeout, should return boolean.
            ---@field render? function|string Function to render a notification buffer.
            ---@field replace? integer|notify.Record Notification record or the record `id` field. Replace an existing notification if still open. All arguments not given are inherited from the replaced notification including message and level.
            ---@field hide_from_history? boolean Hide this notification from the history
            ---@field animate? boolean If false, the window will jump to the timed stage. Intended for use in blocking events (e.g. vim.fn.input)

            --- Display a notification.
            ---@param message string|string[] Notification message
            ---@param level? string|number? Log level. See vim.log.levels
            ---@param opts? plugins.nvim-notify.notify.Options? Notification options
            ---@return notify.Record
            ---@diagnostic disable-next-line: duplicate-set-field
            vim.notify = function(message, level, opts)
                return require('notify')(message, level, opts)
            end
        end,
    },
}
