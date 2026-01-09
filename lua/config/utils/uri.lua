-- URI functions
-- ========================================================================= --

local M = {}

----------------------------------------------------------------------
-- Basic URL / URI validation
----------------------------------------------------------------------

--- Lightweight HTTP(S) URL check.
--- @param url string
--- @return boolean
function M.is_valid(url)
    if type(url) ~= 'string' then
        return false
    end
    -- Require http or https scheme and at least one char after "://"
    return url:match('^https?://.+') ~= nil
end

--- Generic URI validation (any scheme).
--- This is deliberately permissive; adjust pattern if needed.
--- @param str string
--- @return boolean
function M.validate(str)
    if type(str) ~= 'string' then
        return false
    end
    -- scheme = ALPHA *( ALPHA / DIGIT / "+" / "-" / "." )
    return str:match('^[%a][%w+%-%.]*://.+') ~= nil
end

----------------------------------------------------------------------
-- Percent-encoding / decoding
----------------------------------------------------------------------

-- By default, leave unreserved characters as‑is per RFC 3986:
-- ALPHA / DIGIT / "-" / "." / "_" / "~"
local DEFAULT_UNRESERVED =
    'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789%-_%.~'

--- Percent-encode a string.
--- NOTE: By default, space is encoded as "%20" (not "+").
--- @param str string
--- @param unreserved? string  -- characters that should NOT be encoded
--- @return string
function M.encode(str, unreserved)
    if type(str) ~= 'string' then
        return ''
    end
    unreserved = unreserved or DEFAULT_UNRESERVED

    -- Build a fast lookup set for unreserved chars
    local keep = {}
    for i = 1, #unreserved do
        keep[unreserved:sub(i, i)] = true
    end

    -- Encode any byte not in the unreserved set
    return (
        str:gsub('.', function(c)
            if keep[c] then
                return c
            end
            return string.format('%%%02X', string.byte(c))
        end)
    )
end

--- Percent-decode a string.
--- @param str string
--- @return string
function M.decode(str)
    if type(str) ~= 'string' then
        return ''
    end
    -- Replace %HH with the corresponding byte
    return (
        str:gsub('%%(%x%x)', function(hex)
            return string.char(tonumber(hex, 16))
        end)
    )
end

----------------------------------------------------------------------
-- Fetching HTML title from a URL
----------------------------------------------------------------------

--- Internal: run a command and capture stdout, return stdout or nil, err.
--- Prefers vim.system when available (Neovim ≥ 0.10).
--- @param cmd string[]
--- @return string|nil, string|nil
local function run_cmd(cmd)
    -- New API (non-blocking, but we can wrap sync-style)
    if vim and vim.system then
        local obj = vim.system(cmd, { text = true }):wait()
        if obj.code ~= 0 then
            return nil,
                obj.stderr
                    or ('command failed with code ' .. tostring(obj.code))
        end
        return obj.stdout or '', nil
    end

    -- Fallback to io.popen for older Neovim / Lua environments.
    local joined = table.concat(cmd, ' ')
    local handle, err = io.popen(joined .. ' 2>/dev/null')
    if not handle then
        return nil, err or 'io.popen failed'
    end
    local out = handle:read('*a')
    handle:close()
    return out or '', nil
end

--- Try to extract a <title>...</title> from HTML.
--- Very naive HTML parsing by design.
--- @param html string
--- @return string|nil
local function extract_title(html)
    if not html or html == '' then
        return nil
    end

    -- Allow for attributes: <title ...>Title</title>
    local title = html:match('<title[^>]*>(.-)</title>')
    if not title then
        return nil
    end

    -- Strip leading/trailing whitespace and newlines
    title = title:gsub('^%s+', ''):gsub('%s+$', '')
    -- Collapse internal whitespace runs
    title = title:gsub('%s+', ' ')

    return title ~= '' and title or nil
end

--- Fetch HTML page title for a URL.
--- Returns empty string on failure.
--- @param url string
--- @return string
function M.fetch_title(url)
    -- Bail early if the url obviously isn't a URL.
    if not M.is_valid(url) then
        return ''
    end

    -- Use curl to get the page contents.
    -- -sS : silent but show errors
    -- -L  : follow redirects
    local cmd = { 'curl', '-sSL', url }

    local html, err = run_cmd(cmd)
    if not html then
        vim.schedule(function()
            vim.notify(
                'Failed to fetch URL title: '
                    .. tostring(err or 'unknown error'),
                vim.log.levels.DEBUG
            )
        end)
        return ''
    end

    local title = extract_title(html)
    if not title then
        return ''
    end

    return title
end

return M
