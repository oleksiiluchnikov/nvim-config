--[[
    Keymaps Module
    All keybindings organized in one place
--]]

local ai = require('config.ai')

-- Window Focus (Fast switching)
vim.keymap.set('n', '<Left>', '<C-w>h', { desc = 'Focus Left' })
vim.keymap.set('n', '<Right>', '<C-w>l', { desc = 'Focus Right' })

-- AI Accept Keymaps
vim.keymap.set({ 'n', 'i', 'c', 't' }, '<C-y>', function()
    ai.accept_suggestion('word')
end, { desc = 'AI: Accept Word' })

vim.keymap.set({ 'n', 'i', 'c', 't' }, '<C-j>', function()
    ai.accept_suggestion('full')
end, { desc = 'AI: Accept Full Suggestion' })

vim.keymap.set({ 'n', 'i', 'c', 't' }, '<C-l>', function()
    ai.accept_suggestion('line')
end, { desc = 'AI: Accept Line (Cursor to EOL)' })

-- Smart Navigation (Up/Down)
vim.keymap.set({ 'n', 'i', 'v' }, '<Up>', function()
    ai.smart_nav('up')
end, { desc = 'Smart Up' })

vim.keymap.set({ 'n', 'i', 'v' }, '<Down>', function()
    ai.smart_nav('down')
end, { desc = 'Smart Down' })

vim.keymap.set({ 'n', 'i', 'v' }, '<C-Down>', function()
    ai.smart_nav('down')
end, { desc = 'Smart Down (C-Down)' })

-- CodeCompanion
vim.keymap.set({ 'n', 'v' }, '<leader>j', function()
    vim.cmd([[CodeCompanionChat]])
end, { desc = 'CodeCompanion: Toggle chat buffer' })

vim.keymap.set({ 'n', 'v' }, '<leader>x', function()
    vim.cmd([[CodeCompanionChat Add]])
end, { desc = 'CodeCompanion: Add selection to chat' })

-- String Preview
vim.keymap.set('n', '<leader>es', function()
    require('config.utils.string_preview').edit_string()
end, { desc = 'Utils: Edit long string in floating window' })

-- Change Directory
vim.keymap.set('n', '<leader>cd', function()
    local root = vim.fn.expand('%:p:h') -- Get the directory of the current file
    -- Remove oil: prefix from oil.nvim if it exists
    root = root:gsub('^oil://', '')

    if root and root ~= '' then
        vim.cmd('cd ' .. vim.fn.fnameescape(root)) -- Change directory to the root
        -- Display a notification with the new directory
        vim.notify('Changed directory to: ' .. root, vim.log.levels.INFO, {
            timeout = 1500, -- Set a longer timeout for better readability
        })
    else
        -- Show a warning if the directory can't be determined
        vim.notify(
            'Could not determine a valid root directory.',
            vim.log.levels.WARN,
            {
                timeout = 1500,
            }
        )
    end
end, { desc = 'Project: Change to file directory' })

-- Make Test
vim.keymap.set('n', '<leader>m', function()
    vim.cmd('!make test')
end, { desc = 'Project: Run make test' })

vim.keymap.set('n', '<localleader>at', function()
    local url = vim.fn.expand('<cword>')

    -- if not url:match('^https?://') then
    --     vim.notify('Cursor is not on a URL: ' .. url, vim.log.levels.WARN)
    --     return
    -- end

    local row, _ = unpack(vim.api.nvim_win_get_cursor(0))
    local start_col, end_col = string.find(
        vim.api.nvim_get_current_line(),
        vim.pesc(url),
        1,
        true -- plain text search
    )

    if not start_col or not end_col then
        vim.notify('Could not locate URL in line', vim.log.levels.ERROR)
        return
    end

    -- ============================================
    -- HTML Entity Decoder (More Comprehensive)
    -- ============================================
    local function decode_html_entities(str)
        local entities = {
            ['&nbsp;'] = ' ',
            ['&amp;'] = '&',
            ['&lt;'] = '<',
            ['&gt;'] = '>',
            ['&quot;'] = '"',
            ['&#39;'] = '\'',
            ['&apos;'] = '\'',
            ['&ldquo;'] = '"',
            ['&rdquo;'] = '"',
            ['&lsquo;'] = '\'',
            ['&rsquo;'] = '\'',
            ['&mdash;'] = '—',
            ['&ndash;'] = '–',
        }

        local decoded = str:gsub('(&%w+;)', function(entity)
            return entities[entity] or entity
        end)

        -- Decode numeric entities like &#8217; or &#x2019;
        decoded = decoded:gsub('&#(%d+);', function(num)
            local n = tonumber(num)
            if n and n < 128 then
                return string.char(n)
            end
            return '&#' .. num .. ';'
        end)

        return decoded
    end

    -- ============================================
    -- Fetch Title (Non-blocking with vim.system)
    -- ============================================
    local function fetch_title_async(url, callback)
        -- Use sed instead of grep -P for better portability
        local cmd = {
            'sh',
            '-c',
            string.format(
                [[curl -Ls -m 10 '%s' | sed -n 's/.*<title>\(.*\)<\/title>.*/\1/ip;T;q']],
                url:gsub('\'', '\'\\\'\'') -- Proper shell escaping
            ),
        }

        vim.notify('Fetching title...', vim.log.levels.INFO)

        vim.system(cmd, { text = true }, function(obj)
            vim.schedule(function()
                if obj.code ~= 0 then
                    callback(nil, 'curl failed with exit code ' .. obj.code)
                    return
                end

                local title =
                    obj.stdout:gsub('[\n\r]', ''):match('^%s*(.-)%s*$')

                if not title or title == '' then
                    callback(nil, 'No title found')
                    return
                end

                callback(decode_html_entities(title), nil)
            end)
        end)
    end

    -- ============================================
    -- Replace URL with Markdown Link
    -- ============================================
    fetch_title_async(url, function(title, err)
        if err then
            vim.notify('Failed to fetch title: ' .. err, vim.log.levels.WARN)
            return
        end

        local markdown_link = string.format('[%s](%s)', title, url)

        -- Check if the buffer/line is still valid
        local current_line =
            vim.api.nvim_buf_get_lines(0, row - 1, row, false)[1]
        if
            not current_line or not current_line:find(vim.pesc(url), 1, true)
        then
            vim.notify(
                'Buffer changed, cannot replace URL',
                vim.log.levels.WARN
            )
            return
        end

        vim.api.nvim_buf_set_text(
            0,
            row - 1,
            start_col - 1,
            row - 1,
            end_col,
            { markdown_link }
        )
        vim.notify('Replaced URL with title: ' .. title, vim.log.levels.INFO)
    end)
end, { desc = 'Add title to URL' })

vim.keymap.set('n', 'gf', function()
    -- use default gf behavior for normal files
    local filepath = vim.fn.expand('<cfile>')
    if vim.fn.filereadable(filepath) == 1 then
        vim.cmd('edit ' .. filepath)
        return
    end

    -- if current file is in ~/.config/nvim/lua/plugins/.*
    if
        not vim.fn
            .expand('%:p')
            :match(vim.pesc(vim.fn.stdpath('config') .. '/lua/plugins/'))
    then
        return
    end

    local plugin_slug = nil
    local line = vim.api.nvim_get_current_line()

    for word in line:gmatch('%S+') do
        -- the result is like: "          'author/plugin.nvim',"
        -- extract author/plugin.(nvim|lua)

        local match = word:match('^[\'"]?([%w_-]+/[%w_-]+%.%a+)[\'"]?,?$')
        if match then
            plugin_slug = match
            break
        end
    end

    if not plugin_slug then
        vim.notify(
            'No plugin slug found under cursor. Expected format: "author/plugin.nvim".',
            vim.log.levels.WARN
        )
        return
    end

    local plugin_name = plugin_slug:match('/([%w_-]+%.%w+)$')
    if not plugin_name then
        vim.notify(
            'Could not extract plugin name from slug: ' .. plugin_slug,
            vim.log.levels.ERROR
        )
        return
    end

    local full_path = string.format(
        '%s/.local/share/nvim/lazy/%s',
        vim.fn.expand('~'),
        plugin_name
    )

    if vim.fn.isdirectory(full_path) == 1 then
        vim.cmd('edit ' .. full_path)
    else
        vim.notify(
            'Plugin directory not found: ' .. full_path,
            vim.log.levels.ERROR
        )
    end
end)
