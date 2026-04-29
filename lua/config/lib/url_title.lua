--[[
    URL Title Feature
    Async fetch of HTML <title> for URL under cursor, replace with markdown link.
    Extracted from keymaps.lua for reuse.
--]]

local M = {}

-- ============================================================================
--  HTML Entity Decoder
-- ============================================================================

local html_entities = {
    ['&nbsp;'] = ' ',
    ['&amp;'] = '&',
    ['&lt;'] = '<',
    ['&gt;'] = '>',
    ['&quot;'] = '"',
    ['&#39;'] = '\'',
    ['&apos;'] = '\'',
    ['&ldquo;'] = '\226\128\156',
    ['&rdquo;'] = '\226\128\157',
    ['&lsquo;'] = '\226\128\152',
    ['&rsquo;'] = '\226\128\153',
    ['&mdash;'] = '\226\128\148',
    ['&ndash;'] = '\226\128\147',
}

---@param str string
---@return string
local function decode_html_entities(str)
    local decoded = str:gsub('(&%w+;)', function(entity)
        return html_entities[entity] or entity
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

-- ============================================================================
--  Async Title Fetch
-- ============================================================================

---@param url string
---@param callback fun(title: string|nil, err: string|nil)
local function fetch_title_async(url, callback)
    local cmd = {
        'sh',
        '-c',
        string.format(
            [[curl -Ls -m 10 '%s' | sed -n 's/.*<title>\(.*\)<\/title>.*/\1/ip;T;q']],
            url:gsub('\'', '\'\\\'\'')
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

-- ============================================================================
--  Public API
-- ============================================================================

--- Replace URL under cursor with a markdown link [title](url).
--- Fetches the page title asynchronously.
function M.add_title_to_url()
    local url = vim.fn.expand('<cword>')
    local row, _ = unpack(vim.api.nvim_win_get_cursor(0))
    local start_col, end_col = string.find(
        vim.api.nvim_get_current_line(),
        vim.pesc(url),
        1,
        true
    )

    if not start_col or not end_col then
        vim.notify('Could not locate URL in line', vim.log.levels.ERROR)
        return
    end

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
            not current_line
            or not current_line:find(vim.pesc(url), 1, true)
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
end

return M
